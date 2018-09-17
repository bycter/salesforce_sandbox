@isTest
public class ContractFromQuoteCreatorTest {

    @testSetup
    public static void setupData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
    }

    @isTest
    public static void testOverrideGLA() {
        //START - prepare
        c2g__codaGeneralLedgerAccount__c mainAccount = new c2g__codaGeneralLedgerAccount__c(Name = '8888 - main', c2g__ReportingCode__c = '8888', c2g__Type__c = 'Profit and Loss');
        insert mainAccount;

        SBQQ__Quote__c updateQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c quoteLine = [SELECT Id, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__ProductCode__c = :QuoteProductCodes.OFFICE_RENT LIMIT 1];
        update new Product2(Id = quoteLine.SBQQ__Product__c, Override_GLA__c = true, c2g__CODASalesRevenueAccount__c = mainAccount.Id);
        //END - prepare

        Test.startTest();
        updateQuote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
        update updateQuote;
        SBQQ__Subscription__c subscription = [SELECT Id, Override_GLA__c FROM SBQQ__Subscription__c WHERE SBQQ__QuoteLine__c = :quoteLine.Id LIMIT 1];
        System.assertEquals('8888.01', subscription.Override_GLA__c);
        Test.stopTest();
    }

    @isTest
    public static void testNumberOfWorkstations() {
        Test.startTest();
        SBQQ__Quote__c updateQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        updateQuote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
        update updateQuote;
        SBQQ__Subscription__c subscription = [SELECT Number_of_Workstations__c FROM SBQQ__Subscription__c WHERE SBQQ__QuoteLine__r.SBQQ__ProductCode__c = :QuoteProductCodes.OFFICE_RENT LIMIT 1];
        System.assertEquals(1, subscription.Number_of_Workstations__c);
        Test.stopTest();
    }

    @isTest
    public static void testSubscriptionStartEndDate() {
        Test.startTest();
        SBQQ__Quote__c updateQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        updateQuote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
        update updateQuote;
        SBQQ__Subscription__c subscription = [SELECT SBQQ__SubscriptionStartDate__c, SBQQ__SubscriptionEndDate__c FROM SBQQ__Subscription__c WHERE SBQQ__QuoteLine__r.SBQQ__ProductCode__c = :QuoteProductCodes.OFFICE_RENT LIMIT 1];
        System.assertNotEquals(null, subscription.SBQQ__SubscriptionStartDate__c);
        System.assertNotEquals(null, subscription.SBQQ__SubscriptionEndDate__c);
        Test.stopTest();
    }
}