@IsTest
private class DesignCasesUpdaterTest {
    @IsTest
    static void givenDesignCaseWhenLeaseTransactionCaseCreatedThenDesignCaseChanged() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithServiceChargeCapLines();

        User propertyManager = RecordDmlTest.createUser();

        Property__c property = [SELECT Id, Property_Manager__c FROM Property__c WHERE Id = :quote.Property__c];
        property.Property_Manager__c = propertyManager.Id;
        upsert property;

        Opportunity opportunity = [SELECT AccountId FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c];
        opportunity.Briefing_Statement__c = 'test statement';
        update opportunity;

        Contact contact = new Contact(AccountId = opportunity.AccountId, Contact_Type__c = 'In Life Property Contact', LastName = 'Test Contact');
        insert contact;

        //given
        Case designCase = new Case(RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.FIT_OUT_DESIGN_RECORD_TYPE), Quote__c = quote.Id, Customer_Budget__c = 1000);
        insert designCase;

        Test.startTest();
        //when
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        designCase = [SELECT OwnerId, RecordTypeId, Status FROM Case WHERE Id = :designCase.Id];

        //then
        System.assertEquals(designCase.OwnerId, QueueHelper.getRtIdByDeveloperName(QueueHelper.B_C_QUEUE));
        System.assertEquals(designCase.RecordTypeId, RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.BUILDING_CONSTRUCTION_CASE_RECORD_TYPE));
        System.assertEquals(designCase.Status, 'Customer Confirmed');
    }
}