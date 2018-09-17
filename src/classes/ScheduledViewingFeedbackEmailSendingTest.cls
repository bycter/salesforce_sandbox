@isTest
public with sharing class ScheduledViewingFeedbackEmailSendingTest {
    @isTest
    static void givenViewingsWhenScheduledSendingThenRequestsCreatedEmailsSent() {
        //given
        Lead lead = RecordDmlTest.createLead();
        Property__c property1 = RecordDmlTest.createProperty();
        Property__c property2 = RecordDmlTest.createProperty();
        property1.Name = 'Caledonian House';
        property2.Name = 'Denmark Road';
        update property1;
        update property2;

        List<Event> eventsProperty1 = RecordDmlTest.createViewingEvents(5, lead.id, null, property1.Id);
        List<Event> eventsProperty2 = RecordDmlTest.createViewingEvents(6, lead.id, null, property2.Id);
        Event viewing1 = eventsProperty1.get(0);
        Event viewing2 = eventsProperty2.get(0);
        Event viewing3 = eventsProperty1.get(1);
        Event viewing4 = eventsProperty2.get(1);
        Event viewing5 = eventsProperty1.get(2);
        Event viewing6 = eventsProperty2.get(2);
        Event viewing7 = eventsProperty1.get(3);
        Event viewing8 = eventsProperty2.get(3);
        Event viewing9 = eventsProperty1.get(4);
        Event viewing10 = eventsProperty2.get(4);
        Event viewing11 = eventsProperty2.get(5);

        Integer limitsEmailInvocations = Limits.getEmailInvocations();

        //when
        new ScheduledViewingFeedbackEmailSending().sendRequests();

        //then        
        System.assertEquals(1, [select count() from Feedback_Request__c]);

        Feedback_Request__c feedbackRequest = [
                select Id, Property1__c, Property1_Name__c, Viewing1_Id__c, Property10__c, Property10_Name__c, Viewing10_Id__c
                from Feedback_Request__c
        ][0];
        System.assertEquals(property1.Id, feedbackRequest.Property1__c);
        System.assertEquals(property1.Name, feedbackRequest.Property1_Name__c);
        System.assertEquals(viewing1.Id, feedbackRequest.Viewing1_Id__c);
        //checking only first and last
        System.assertEquals(property2.Id, feedbackRequest.Property10__c);
        System.assertEquals(property2.Name, feedbackRequest.Property10_Name__c);
        System.assertEquals(viewing10.Id, feedbackRequest.Viewing10_Id__c);

        System.assertEquals(limitsEmailInvocations + 1, Limits.getEmailInvocations(), 'should have decreased');
    }

    @isTest
    static void givenLeadWithEmptyEmailAndViewingWhenSendThenNoFailure() {
        //given
        Lead lead = RecordDmlTest.createLead();
        lead.Email = null;
        update lead;
        Property__c property1 = RecordDmlTest.createProperty();
        property1.Name = 'Caledonian House';
        update property1;
        RecordDmlTest.createViewingEvent(lead.id, null, property1.Id);
        //when
        new ScheduledViewingFeedbackEmailSending().sendRequests();
        //then
    }

    @isTest
    static void givenOpportunityAndContactAndViewingWhenSendThenRequestSent() {
        //given
        Integer limitsEmailInvocations = Limits.getEmailInvocations();

        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        Database.insert(p2);

        Property__c testProperty = RecordDmlTest.createProperty();
        testProperty.Name = 'Caledonian House';
        update testProperty;

        Opportunity opportunity = RecordDmlTest.createOpportunity('Conventional');
        Contact contact = RecordDmlTest.createContact();

        Event viewing1 = RecordDmlTest.createViewingEvent(contact.id, opportunity.Id, testProperty.Id);

        //when
        new ScheduledViewingFeedbackEmailSending().sendRequests();

        //then        
        System.assertEquals(1, [select count() from Feedback_Request__c]);

        Feedback_Request__c feedbackRequest = [
                select Id, Property1__c, Property1_Name__c, Viewing1_Id__c, Property10__c, Property10_Name__c, Viewing10_Id__c
                from Feedback_Request__c
        ][0];
        System.assertEquals(testProperty.Id, feedbackRequest.Property1__c);
        System.assertEquals(testProperty.Name, feedbackRequest.Property1_Name__c);
        System.assertEquals(viewing1.Id, feedbackRequest.Viewing1_Id__c);

        System.assertEquals(limitsEmailInvocations + 1, Limits.getEmailInvocations(), 'should have decreased');
    }

    @isTest
    static void givenOpportunityAndContactAndLeadViewingsWhenSendThenRequestSent() {
        //given
        Integer limitsEmailInvocations = Limits.getEmailInvocations();

        Product2 p2 = new Product2(Name = 'Test Product', isActive = true);
        Database.insert(p2);

        Property__c testProperty = RecordDmlTest.createProperty();
        testProperty.Name = 'Caledonian House';
        update testProperty;

        Opportunity opportunity = RecordDmlTest.createOpportunity('Conventional');
        Contact contact = RecordDmlTest.createContact();

        Event viewing1 = RecordDmlTest.createViewingEvent(contact.id, opportunity.Id, testProperty.Id);

        Lead lead = RecordDmlTest.createLead();
        Property__c property2 = RecordDmlTest.createProperty();
        property2.Name = 'Denmark Road';
        update property2;
        Event viewing2 = RecordDmlTest.createViewingEvent(lead.id, null, property2.Id);

        //when
        new ScheduledViewingFeedbackEmailSending().sendRequests();

        //then        
        System.assertEquals(2, [select count() from Feedback_Request__c]);

        Feedback_Request__c feedbackRequest = [
                select Id, Property1__c, Property1_Name__c, Viewing1_Id__c, Property10__c, Property10_Name__c, Viewing10_Id__c
                from Feedback_Request__c
                where Viewing1_Id__c = :viewing1.Id
        ][0];
        System.assertEquals(testProperty.Id, feedbackRequest.Property1__c);
        System.assertEquals(testProperty.Name, feedbackRequest.Property1_Name__c);
        System.assertEquals(viewing1.Id, feedbackRequest.Viewing1_Id__c);

        feedbackRequest = [
                select Id, Property1__c, Property1_Name__c, Viewing1_Id__c, Property10__c, Property10_Name__c, Viewing10_Id__c
                from Feedback_Request__c
                where Viewing1_Id__c = :viewing2.Id
        ][0];
        System.assertEquals(property2.Id, feedbackRequest.Property1__c);
        System.assertEquals(property2.Name, feedbackRequest.Property1_Name__c);
        System.assertEquals(viewing2.Id, feedbackRequest.Viewing1_Id__c);

        System.assertEquals(limitsEmailInvocations + 1, Limits.getEmailInvocations(), 'should have decreased');
    }
}