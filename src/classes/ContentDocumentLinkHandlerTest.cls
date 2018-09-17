@isTest
public class ContentDocumentLinkHandlerTest {

    @testSetup
    public static void initData() {
        Property__c property = new Property__c(Street__c = 'Test');
        insert property;

        Inventory__c inventory = new Inventory__c(Name = 'Test', Property__c = property.Id, Sales_Status__c = 'Available');
        insert inventory;

        SBQQ__Quote__c quote = RecordDmlTest.createCPQQuote();

        Case entityCase = new Case(
                RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Fit_Out_Design' AND SobjectType = 'Case'].get(0).Id,
                Inventory__c = inventory.Id,
                Quote__c = quote.Id,
                AccountId = quote.SBQQ__Account__c,
                Customer_Budget__c = 1000);
        insert entityCase;

        ContentVersion contentVersion = new ContentVersion(
                Title = 'Test document',
                PathOnClient = 'Test.pdf',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true);
        insert contentVersion;

        ContentDocumentLink contentlink = new ContentDocumentLink(
                LinkedEntityId = entityCase.Id,
                ShareType = 'V',
                ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1].get(0).ContentDocumentId);
        insert contentlink;

        ContentDocument contentDocument = [SELECT FileExtension FROM ContentDocument LIMIT 1];
    }

    @isTest
    public static void checkForQuoteDocumentExistence() {
        Case entityCase = [SELECT Id, Quote__c FROM Case LIMIT 1];
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :entityCase.Quote__c], 'Additional document of the quote is not created');
    }

    @isTest
    public static void checkForInventoryDocumentExistence() {
        Inventory__c inventory = [SELECT Id FROM Inventory__c LIMIT 1];
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink Where LinkedEntityId = :inventory.Id], 'Inventory document is not created');
    }

    @isTest
    public static void checkForAccountDocumentExistence() {
        Case entityCase = [SELECT Id, AccountId FROM Case LIMIT 1];
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink Where LinkedEntityId = :entityCase.AccountId], 'Account document is not created');
    }
}