@IsTest
private class CaseTriggerHandlerTest {
    @isTest static void testCaseInventory() {
        Account newAccount = RecordDmlTest.createAccount();
        Contact newContact = new Contact(AccountId = newAccount.Id, FirstName = 'Sidor', LastName = 'Sidorov', Email = 'test@test.com');
        insert newContact;

        SBQQ__Quote__c newQuote = RecordDmlTest.generateConventionalQuoteWithLines(ProductService.PRODUCT_CODE_OFFICE_RENT);

        Case testCase;
        Test.startTest();
        testCase = new Case(
                AccountId = newAccount.Id,
                ContactId = newContact.Id,
                RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.LEASE_TRANSACTION_RECORD_TYPE),
                Quote__c = newQuote.Id,
                Status = 'New',
                ReasonForLoss__c = 'Test',
                Origin = 'Email'
        );
        insert testCase;

        testCase = [SELECT Id, Inventory__c FROM Case WHERE Id = :testCase.Id];
        System.assert(testCase.Inventory__c != null);

        Test.stopTest();
    }

    @isTest static void createCaseUpdateContract() {
        Case testCase = prepareTestCase(Constants.STATUS_CLOSED_LOST);
        Id quote = testCase.Quote__c;
        SBQQ__Quote__c testQuote = [SELECT Id, Contract__r.Status FROM SBQQ__Quote__c WHERE Id = :quote];
        System.assertEquals(Constants.STATUS_NOT_COMPLETED, testQuote.Contract__r.Status);
    }

    @isTest
    static void givenCasesWithOpenTasksWhenCaseCompletedThenCaseNotUpdated() {
        Case caseWithOpenTask = new Case(Subject = 'Test Case', Status = 'Open');
        Case caseWithoutOpenTask = new Case(Subject = 'Test Case', Status = 'Open');
        insert caseWithOpenTask;
        insert caseWithoutOpenTask;

        Task openTask = new Task(Status = 'Open', WhatId = caseWithOpenTask.Id);
        Task completedTask = new Task(Status = 'Completed', WhatId = caseWithoutOpenTask.Id);
        insert openTask;
        insert completedTask;

        caseWithOpenTask.Status = 'Completed';
        caseWithoutOpenTask.Status = 'Completed';


        update caseWithoutOpenTask;
        try {
            update caseWithOpenTask;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        System.assertEquals('Open', [SELECT Id, Status FROM Case WHERE Id = :caseWithOpenTask.Id].Status);
        System.assertEquals('Completed',[SELECT Id, Status FROM Case WHERE Id = :caseWithoutOpenTask.Id].Status);
    }

    /*@isTest
    static void givenAccountwhenSLACaseCreatedThenEntitlementPopulatedFromAccount() {
        //given TODO: UNCOMMENT
        Property__c property = RecordDmlTest.createProperty();

        SBQQ__Quote__c quote = RecordDmlTest.createCPQQuote();
        quote.Property__c = property.Id;
        upsert quote;

        Id slaCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lease Transaction').getRecordTypeId();

        System.assertEquals(1, [select count() from Entitlement]);

        Case testCase = new Case(
                AccountId = quote.SBQQ__Account__c,
                Quote__c = quote.Id,
                recordTypeId = slaCaseRecordTypeId,
                Status = 'New',
                Origin = 'Email');
        insert testCase;

        testCase = [select id, EntitlementId from Case where id = :testCase.id];

        System.assertNotEquals(null, testCase.EntitlementId);
    }*/

    private static Case prepareTestCase(String status) {
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lease Transaction').getRecordTypeId();

        User testUser = RecordDmlTest.createUser('bwstandarduser', 'BW Standard User');
        insert testUser;

        Account newAccount = new Account(Name = 'Test Company', Industry = 'Banking');
        insert newAccount;

        Contact newContact = new Contact(AccountId = newAccount.Id, FirstName = 'Sidor', LastName = 'Sidorov',
                Email = 'test@test.com');
        insert newContact;

        Opportunity newOpportunity = new Opportunity(AccountId = newAccount.Id, Name = 'Test Opportunity',
                Type = 'Existing Customer', StageName = 'Qualified', CloseDate = System.today() + 10, Product__c = 'Office',
                Region__c = 'Manchester City Centre', LeadSource = 'Advertisement');
        insert newOpportunity;

        Property__c newProperty = new Property__c(Name = 'Test property', Property_Manager__c = testUser.id,
                Region__c = 'Manchester City Centre', Street__c = 'TestStreet');
        insert newProperty;

        SBQQ__Quote__c newQuote = RecordDmlTest.createQuote(newProperty, newOpportunity, OpportunityService.CONVENTIONAL_RECORD_TYPE);

        Contract newContract = RecordDmlTest.createContract(newQuote, newProperty);

        newQuote.Contract__c = newContract.Id;

        update newQuote;

        Case testCase = new Case(
                AccountId = newAccount.Id,
                ContactId = newContact.Id,
                recordTypeId = caseRecordTypeId,

                Quote__c = newQuote.Id,
                Status = 'New',
                ReasonForLoss__c = 'Test',
                Origin = 'Email');
        insert testCase;
        testCase.Status = status;
        update testCase;
        return testCase;
    }
}