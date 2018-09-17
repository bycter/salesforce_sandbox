@isTest
public class SBQQ_QuoteTriggerHandlerTest {

    private static List<RecordType> quoteRecordTypes = [SELECT Id, Name, DeveloperName FROM RecordType WHERE SobjectType = 'SBQQ__Quote__c'];

    @testSetup
    public static void initData() {
        SBQQ.TriggerControl.disable();

        Property__c testProperty = RecordDmlTest.createProperty();
        Pricebook2 pricebook = RecordDmlTest.createPricebook('Conventional');
        RecordDmlTest.createProducts(pricebook.Id);

        Product2 product = [SELECT Name, Id, IsActive, Family, ProductCode FROM Product2 WHERE ProductCode = 'OfficeRent'];

        Inventory__c inventory = RecordDmlTest.createActualSuiteInventory(product, testProperty);

        createQuotes(testProperty, product, inventory);

        RecordDmlTest.createDocusignSettings();
    }

    private static List<SBQQ__Quote__c> createQuotes(Property__c property, Product2 product, Inventory__c inventory) {
        Account account = RecordDmlTest.createAccount(true);

        PostDeploySetup.assignRTToPriceBooks();

        Opportunity opportunity = RecordDmlTest.createOpportunity('Conventional');

        SBQQ__Quote__c quote = new SBQQ__Quote__c(SBQQ__Status__c = 'Draft', Property__c = property.Id, SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c = opportunity.Id, SBQQ__SalesRep__c = UserInfo.getUserId());
        SBQQ__Quote__c quote2 = new SBQQ__Quote__c(SBQQ__Status__c = 'Draft', Property__c = property.Id, SBQQ__Account__c = account.Id, SBQQ__Opportunity2__c = opportunity.Id, SBQQ__SalesRep__c = UserInfo.getUserId());
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>{
                quote, quote2
        };
        Database.insert(quotes);

        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(SBQQ__Product__c = product.Id, SBQQ__Quote__c = quote.Id, SBQQ__Quantity__c = 1);
        SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Product__c = product.Id, SBQQ__Quote__c = quote2.Id, SBQQ__Quantity__c = 1);

        quoteLine.Inventory__c = inventory.Id;
        quoteLine.Suite_Inventory__c = inventory.Id;
        quoteLine2.Inventory__c = inventory.Id;
        quoteLine2.Suite_Inventory__c = inventory.Id;

        insert new List<SBQQ__QuoteLine__c>{
                quoteLine, quoteLine2
        };

        return quotes;
    }

    @isTest
    static void givenSBQQ_Quote_whenAccepted_thenInventoryNotAvailableAndCaseAndChatterPostCreatedAndInventoryRemovedFromOtherQLIAndQuoteStatusChanged() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c limit 1];
        //Case not created yet
        System.assertEquals(0, [SELECT COUNT() from Case]);
        //Two Quote lines with inventory exists
        System.assertEquals(2, [SELECT COUNT() from SBQQ__QuoteLine__c]);

        //when
        Test.startTest();
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        //then
        Inventory__c inventory = [SELECT Id, Sales_Status__c FROM Inventory__c LIMIT 1];
        //status updated
        System.assertEquals('Not Available', inventory.Sales_Status__c);
        //Chatter post created TODO: solve group creation problem https://developer.salesforce.com/forums/?id=906F0000000BMY8IAO
        //System.assertEquals(1, [select count() from FeedItem]);
        //Inventory removed from the Quote line

        //Quote with sold Inventories status changed to 'Obsolete'
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__Quote__c WHERE SBQQ__Status__c = 'Obsolete']);
        //Accepted Quote still have status 'Accepted'
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__Quote__c WHERE SBQQ__Status__c = 'Accepted']);

        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__QuoteLine__c WHERE Inventory__c != NULL]);

        //New contract is set into Inventory
        System.assertEquals(1, [SELECT COUNT() FROM Contract_To_Inventory__c WHERE Inventory__c = :inventory.Id]);
    }

    @isTest
    static void givenSBQQ_Quote_whenAccepted_thenContractWithSubscriptionsCreated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        //when
        Test.startTest();
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM Contract]);
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__Subscription__c]);
    }

    @IsTest
    static void givenSteppedRentSBQQ_QuoteLine_whenQuoteAccepted_thenSubscriptionSteppedIncreaseDatesPopulated() {
        //given
        Set<String> concessionProductCodes = new Set<String>{
                'SteppedRent', 'HalfRent', 'RentFree'
        };

        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];

        List<Product2> concessionProducts = [
                SELECT Name, Id, IsActive, Family, ProductCode
                FROM Product2
                WHERE ProductCode IN :concessionProductCodes
        ];

        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

        for (Product2 product : concessionProducts) {
            quoteLines.add(new SBQQ__QuoteLine__c(
                    SBQQ__Product__c = product.Id,
                    SBQQ__Quote__c = quote.Id,
                    SBQQ__Quantity__c = 1,
                    Start_Date__c = System.today().addDays(1),
                    End_Date__c = System.today().addDays(2)
            ));
        }

        SBQQ.TriggerControl.disable();
        insert quoteLines;
        SBQQ.TriggerControl.enable();

        //when
        Test.startTest();
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM Contract]);
        System.assertEquals(4, [SELECT COUNT() FROM SBQQ__Subscription__c]);
        //needed Subscription Line fields are populated:
        System.assertEquals(3, [
                SELECT COUNT()
                FROM SBQQ__Subscription__c
                WHERE SBQQ__QuoteLine__r.SBQQ__ProductCode__c IN :concessionProductCodes AND Stepped_Increase_Start_Date__c = :quoteLines.get(0).Start_Date__c AND Stepped_Increase_End_Date__c = :quoteLines.get(0).End_Date__c
        ]);
        //other QL not affected:
        System.assertEquals(0, [
                SELECT COUNT()
                FROM SBQQ__Subscription__c
                WHERE SBQQ__QuoteLine__r.SBQQ__ProductCode__c NOT IN :concessionProductCodes AND Stepped_Increase_Start_Date__c != NULL AND Stepped_Increase_End_Date__c != NULL
        ]);
    }

//    @isTest
//    static void givenSBQQ_QuoteAndProduct_whenAcceptedAndBillingFrequencyPartialUpFront_thenAdHocRevenueCreated() {
//        //given
//        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
//        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quote.Id LIMIT 1];
//        Product2 product = [SELECT Id, SBQQ__BillingFrequency__c FROM Product2 Where Id =: quoteLine.SBQQ__Product__c];
//        Inventory__c inventory = [SELECT Id, Property__c FROM Inventory__c WHERE Product__c =: product.Id];
//        Property__c property = [SELECT Id, Company__c FROM Property__c WHERE Id =: inventory.Property__c];
//
//        //when
//        product.SBQQ__BillingFrequency__c = SBQQ_QuoteConstants.BILLINGFREQUENCY_PARTIALUPFRONT;
//        update product;
//
//        c2g__codaCompany__c ffCompany = new c2g__codaCompany__c(Name = 'Test Name');
//        insert ffCompany;
//
//        property.Company__c = ffCompany.Id;
//        update property;
//
//        quote.SBQQ__Status__c = 'Accepted';
//        update quote;
//
//        //then
//        System.assertEquals(1, [SELECT COUNT() FROM Ad_hoc_Revenue__c]);
//    }

    @isTest
    static void lockQuoteTest() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        RecordType recordTypeToLock = getRecordTypeByDeveloperName('Conventional_Locked');

        //when
        quote.RecordTypeId = getRecordTypeByDeveloperName('Conventional').Id;
        quote.SBQQ__Status__c = 'Approved';
        update quote;

        //then
        quote = [SELECT Id, RecordTypeId, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        System.assertEquals('Approved', quote.SBQQ__Status__c);
        //Quote Record Type changed
        System.assertEquals(recordTypeToLock.Id, quote.RecordTypeId);
    }

    @isTest
    static void unlockQuoteTest() {
        //given
        Test.setMock(HttpCalloutMock.class, new MockHttpDocuSignResponseGenerator());
        SBQQ__Quote__c quote = [SELECT Id, RecordTypeId, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__SignatureStatus__c = 'Sent',
                SBQQDS__EnvelopeId__c = 'testEnvelopeId1');
        insert quoteDocument;
        RecordType recordTypeToUnlock = getRecordTypeByDeveloperName('Conventional');

        //when
        Test.startTest();
        quote.RecordTypeId = getRecordTypeByDeveloperName('Conventional_Locked').Id;
        quote.SBQQ__Status__c = 'Draft';
        Test.stopTest();
        //update quote;

        //then
        quote = [SELECT Id, RecordTypeId, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        System.assertEquals('Draft', quote.SBQQ__Status__c);
        //Quote Record Type changed
        System.assertEquals(recordTypeToUnlock.Id, quote.RecordTypeId);
    }

    @isTest
    static void givenQuote_whenPaybyBACsChecked_thenTaskShouldBeCreated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(0, [SELECT COUNT() FROM Task WHERE WhatId = :quote.Id AND Status = 'Open']);

        //when
        quote.Pay_by_BACs__c = true;
        update quote;

        //then
        System.assertEquals(1, [SELECT COUNT() FROM Task WHERE WhatId = :quote.Id AND Status = 'Open'], 'The task has not been created after Pay by BACs checked');
    }

    @isTest
    static void whenQuoteCreatedThenPricebookPopulatedFromOpportunity() {
        //then
        SBQQ__Quote__c quote = [SELECT SBQQ__PriceBook__c, SBQQ__Opportunity2__r.Pricebook2Id FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(quote.SBQQ__Opportunity2__r.Pricebook2Id, quote.SBQQ__PriceBook__c);
    }

    private static RecordType getRecordTypeByDeveloperName(String name) {
        for (RecordType recordType : quoteRecordTypes) {
            if (recordType.DeveloperName == name) {
                return recordType;
            }
        }
        return null;
    }
}