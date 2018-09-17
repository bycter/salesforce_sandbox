/**
 * Created by v2.nareyko on 19.1.18.
 */
@IsTest
private class OpportunityTriggerHandlerTest {
    private static final String TEST_DESCRIPTION = 'lorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem';

    @IsTest
    static void createTaskForCoordinator_Completed_Test() {
        Property__c testProperty = RecordDmlTest.createProperty();
        testProperty.Serviced_Space_Coordinator__c = UserInfo.getUserId();
        update testProperty;

        Opportunity testOpportunity = RecordDmlTest.createOpportunity(OpportunityService.VIRTUAL_RECORD_TYPE_NAME);
        SBQQ__Quote__c testQuote = RecordDmlTest.createQuote(testProperty, testOpportunity, 'Virtual');
        testOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id=: testOpportunity.Id];
        System.assertEquals(OpportunityService.STATUS_QUALIFIED, testOpportunity.StageName, 'Initial Opportunity.StageName: ' + OpportunityService.STATUS_QUALIFIED);

        Integer totalTasks = [SELECT COUNT() FROM Task];
        System.assertEquals(0, totalTasks);

        Test.startTest();
        testOpportunity.Deposit_Paid__c = true;
        testOpportunity.Briefing_Statement__c = TEST_DESCRIPTION;
        testOpportunity.StageName = OpportunityService.STATUS_TERMS_AGREED;
        testOpportunity.Compliance_Check_Complete__c = 'Yes';
        update testOpportunity;
        totalTasks = [SELECT COUNT() FROM Task];
        System.assertEquals(0, totalTasks, 'Tasks should not be created for Virtual Opportunity');

        testOpportunity.StageName = OpportunityService.STATUS_COMPLETED;
        update testOpportunity;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, OwnerId, Description, Subject, Type, Property__c, Status, Priority FROM Task];
        System.assertEquals(1, tasks.size(), 'New Tasks should be created for Completed Virtual Opportunity');
        System.assertEquals(TaskService.TYPE_VIRTUAL_ONBOARDING, tasks.get(0).Type, 'Task type should be: ' + TaskService.TYPE_VIRTUAL_ONBOARDING);
        System.assertEquals(TaskService.STATUS_OPEN, tasks.get(0).Status, 'Task status should be: ' + TaskService.STATUS_OPEN);
        System.assertEquals(TEST_DESCRIPTION, tasks.get(0).Description, 'Task Description should be: ' + TEST_DESCRIPTION);
        System.assertEquals(testProperty.Id, tasks.get(0).Property__c);
        System.assertEquals(UserInfo.getUserId(), tasks.get(0).OwnerId);
    }

    @IsTest
    static void createTaskForCoordinator_MeetingBooked_Test() {
        Contact theContact = RecordDmlTest.createContact();
        Property__c testProperty = RecordDmlTest.createProperty();
        testProperty.Serviced_Space_Coordinator__c = UserInfo.getUserId();
        update testProperty;

        Opportunity testOpportunity = RecordDmlTest.createOpportunity(OpportunityService.VIRTUAL_RECORD_TYPE_NAME);
        Event theEvent = RecordDmlTest.createEvent();
        theEvent.Property__c = testProperty.Id;
        theEvent.WhoId = theContact.Id;
        update theEvent;
        testOpportunity = [SELECT Id, StageName FROM Opportunity WHERE Id=: testOpportunity.Id];
        System.assertEquals(OpportunityService.STATUS_QUALIFIED, testOpportunity.StageName, 'Initial Opportunity.StageName: ' + OpportunityService.STATUS_QUALIFIED);

        Integer totalTasks = [SELECT COUNT() FROM Task];
        System.assertEquals(0, totalTasks);

        Test.startTest();
        testOpportunity.Briefing_Statement__c = TEST_DESCRIPTION;
        testOpportunity.StageName = OpportunityService.STATUS_TERMS_AGREED;
        testOpportunity.Compliance_Check_Complete__c = 'Yes';
        testOpportunity.Last_Event_ID__c = theEvent.Id;
        update testOpportunity;
        totalTasks = [SELECT COUNT() FROM Task];
        System.assertEquals(0, totalTasks, 'Tasks should not be created for Virtual Opportunity');

        testOpportunity.StageName = OpportunityService.STATUS_MEETING_BOOKED;
        update testOpportunity;
        Test.stopTest();

        List<Task> tasks = [SELECT Id, OwnerId, Description, Subject, Type, Property__c, Status, Priority, WhoId FROM Task];
        System.assertEquals(1, tasks.size(), 'New Tasks should be created for Completed Virtual Opportunity');
        System.assertEquals(TaskService.SUBJECT_VIRTUAL_CUSTOMER_ID, tasks.get(0).Subject, 'Task Subject should be: ' + TaskService.SUBJECT_VIRTUAL_CUSTOMER_ID);
        System.assertEquals(TaskService.STATUS_OPEN, tasks.get(0).Status, 'Task status should be: ' + TaskService.STATUS_OPEN);
        System.assertEquals(testProperty.Id, tasks.get(0).Property__c);
        System.assertEquals(UserInfo.getUserId(), tasks.get(0).OwnerId);
        System.assertEquals(theContact.Id, tasks.get(0).WhoId);
    }

    @IsTest
    static void singleOpportunityInsertTest() {
        //Given
        Opportunity opportunity = generateOpportunities(1).get(0);

        //When
        insert opportunity;
        List<RecordType> pricebookRecordType = [
                SELECT Id
                FROM RecordType
                WHERE DeveloperName = 'Virtual'
                AND SobjectType = 'Pricebook2'
        ];
        List<Pricebook2> pricebooks = [
                SELECT Id
                FROM Pricebook2
                WHERE IsActive = TRUE
                AND RecordTypeId = :pricebookRecordType.get(0).Id
        ];

        //Then
        if(pricebooks.size() > 0) {
            System.assertEquals(pricebooks.get(0).Id, opportunity.Pricebook2Id);
        } else {
            System.assertEquals(null, opportunity.Pricebook2Id);
        }
    }

    @IsTest
    static void manyOpportunityInsertTest() {
        //Given
        List<Opportunity> opportunities = generateOpportunities(100);

        //When
        insert opportunities;
        List<Pricebook2> pricebooks = [SELECT Id FROM Pricebook2 WHERE RecordType.DeveloperName = 'Virtual'];

        //Then
        if(pricebooks.size() > 0 && pricebooks.size() == 1) {
            for(Opportunity opportunity: opportunities) {
                System.assertEquals(pricebooks.get(0).Id, opportunity.Pricebook2Id);
            }
        }
    }

    @IsTest
    private static void testConventionalOpportunityStatusCalculation() {
        //given
        Property__c testProperty = RecordDmlTest.createProperty();
        Opportunity testOpportunity = RecordDmlTest.createOpportunity(OpportunityService.CONVENTIONAL_RECORD_TYPE);
        SBQQ__Quote__c testQuote = RecordDmlTest.createQuote(testProperty, testOpportunity, 'Conventional');
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__ElectronicSignature__c = true
        );
        insert quoteDocument;
        quoteDocument = [SELECT SBQQ__ElectronicSignature__c, SBQQ__Opportunity__c, Quote_Record_Type__c, Signature_Status__c FROM SBQQ__QuoteDocument__c WHERE Id = :quoteDocument.Id];
        SBQQ_QuoteDocumentService theDocumentService = new SBQQ_QuoteDocumentService();
        Test.startTest();
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Qualified', testOpportunity.StageName);
        quoteDocument.Signature_Status__c = 'Sent';
        theDocumentService.updateParentOpportunities(new List<SBQQ__QuoteDocument__c>{quoteDocument});
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Terms Out', testOpportunity.StageName);
        quoteDocument.Signature_Status__c = 'Completed';
        theDocumentService.updateParentOpportunities(new List<SBQQ__QuoteDocument__c>{quoteDocument});
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Instructed', testOpportunity.StageName);
        Test.stopTest();
    }

    @IsTest
    private static void testVirtualOpportunityStatusCalculation() {
        //given
        Property__c testProperty = RecordDmlTest.createProperty();
        Opportunity testOpportunity = RecordDmlTest.createOpportunity(OpportunityService.VIRTUAL_RECORD_TYPE_NAME);
        SBQQ__Quote__c testQuote = RecordDmlTest.createQuote(testProperty, testOpportunity, 'Virtual');
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__ElectronicSignature__c = true
        );
        insert quoteDocument;
        quoteDocument = [SELECT SBQQ__ElectronicSignature__c, SBQQ__Opportunity__c, Quote_Record_Type__c, Signature_Status__c FROM SBQQ__QuoteDocument__c WHERE Id = :quoteDocument.Id];
        SBQQ_QuoteDocumentService theDocumentService = new SBQQ_QuoteDocumentService();
        Test.startTest();
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Qualified', testOpportunity.StageName);
        testOpportunity.Briefing_Statement__c = 'Test';
        testOpportunity.Compliance_Check_Complete__c = 'Yes';
        update testOpportunity;
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Check Complete', testOpportunity.StageName);
        quoteDocument.Signature_Status__c = 'Completed';
        theDocumentService.updateParentOpportunities(new List<SBQQ__QuoteDocument__c>{quoteDocument});
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Terms Agreed', testOpportunity.StageName);
        testOpportunity.Deposit_Paid__c = true;
        update testOpportunity;
        testOpportunity = [SELECT StageName FROM Opportunity WHERE Id = :testOpportunity.Id];
        System.assertEquals('Completed', testOpportunity.StageName);
        Test.stopTest();
    }

    private static List<Opportunity> generateOpportunities(Integer n) {
        List<Opportunity> result = new List<Opportunity>();
        Property__c property = new Property__c();
        property.Name = 'AssignPriceBookOnOpportunityTriggerTest';
        property.Active__c = true;
        property.Region__c = 'Leeds';
        property.Street__c = 'yl. Pupkina, d. 228';
        insert property;

        RecordType recordType = [SELECT Id, DeveloperName FROM RecordType
        WHERE DeveloperName = 'Virtual'
        AND IsActive = TRUE
        AND SobjectType = 'Opportunity'];

        while (n-- != 0) {
            Opportunity opportunity = new Opportunity();
            opportunity.Name = 'Assign PriceBook to Opportunity test ' + n;
            opportunity.StageName = 'Qualified';
            opportunity.Type = 'New Customer';
            opportunity.CloseDate = Date.valueOf('2020-01-01');
            opportunity.Region__c = 'Leeds';
            opportunity.LeadSource = 'Advertisement';
            opportunity.Sub_Source__c = 'Building Signage';
            opportunity.Channel__c = 'Email';
            opportunity.RecordTypeId = recordType.Id;
            opportunity.RecordType = recordType;
            result.add(opportunity);
        }
        return result;
    }
}