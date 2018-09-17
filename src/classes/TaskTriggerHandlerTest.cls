@isTest
public class TaskTriggerHandlerTest {

    @testSetup
    public static void initData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();
        List<Task> tasks = new List<Task>{
                new Task(Subject = 'Test', WhatId = quote.Id, Status = 'Open', System_Code__c = TaskService.PAY_BY_BACS_SYSTEM_CODE),
                new Task(Subject = TaskService.SUBJECT_SETUP_CD, WhatId = quote.Id, Status = 'Open', System_Code__c = TaskService.SETUP_CD_SYSTEM_CODE)
        };
        insert tasks;

    }

    @isTest
    static void givenCase_whenTaskCreated_thenFieldsPopulated() {
        Case newCase = RecordDmlTest.createCaseRelatedToInventory();
        Task newTask = new Task(Subject = 'Test Task', WhatId = newCase.Id);
        insert newTask;

        newTask = [SELECT Id, Property__c, Inventory__c FROM Task WHERE Id = :newTask.Id];
        System.assertEquals(newTask.Property__c, newCase.Property__c);
        System.assertEquals(newTask.Inventory__c, newCase.Inventory__c);
    }


    @isTest
    static void givenQuoteAndTask_whenTaskCompleted_thenQuoteUpdated() {
        //given
        Task task = [SELECT Id, Status FROM Task WHERE System_Code__c = :TaskService.PAY_BY_BACS_SYSTEM_CODE LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(false, quote.Pay_by_BACs_Approved__c);

        //when
        Test.startTest();
        task.Status = 'Completed';
        update task;

        //then
        quote = [select Id, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c limit 1];
        System.assertEquals(true, quote.Pay_by_BACs_Approved__c, 'Pay by Bacs Approved field should be updated after the task completed');
        Test.stopTest();
    }

    @isTest
    private static void testAcceptQuotesForCompletedTasks() {
        //given
        Task setupCDTask = [SELECT Id, Status FROM Task WHERE System_Code__c = :TaskService.SETUP_CD_SYSTEM_CODE LIMIT 1];
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__PrimaryContact__c FROM SBQQ__Quote__c LIMIT 1];

        Inventory__c inventory = [SELECT Id FROM Inventory__c LIMIT 1];
        Id designCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Design').getRecordTypeId();
        Case designCase = new Case(
                RecordTypeId = designCaseRecordTypeId,
                Inventory__c = inventory.Id,
                ContactId = quote.SBQQ__PrimaryContact__c,
                Customer_Budget__c = 1000
        );
        insert designCase;

        //when
        Test.startTest();
        setupCDTask.Status = 'Completed';
        update setupCDTask;

        //then
        quote = [select Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(SBQQ_QuoteConstants.STATUS_ACCEPTED, quote.SBQQ__Status__c);
        Test.stopTest();
    }
}