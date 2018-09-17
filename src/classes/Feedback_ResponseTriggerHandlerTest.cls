@IsTest
private class Feedback_ResponseTriggerHandlerTest {
    static testMethod void givenPropertiesAndContact_whenNewFeedbackResponseCreated_thenCustomerFeedbacksCreatedAndLinked() {
        //given
        Property__c property = new Property__c(Name = '111 Piccadilly', Region__c = 'Alderley Park', Street__c = 'Property#1 address');
        insert property;
        Product2 p2 = RecordDmlTest.createProducts().get(0);
        Contact contact = new Contact(LastName = 'Last');
        insert contact;

        Opportunity opportunity = RecordDmlTest.createOpportunity('Conventional');
        Event viewing1 = RecordDmlTest.createViewingEvent(contact.id, opportunity.Id, property.Id);

        Feedback_Request__c feedbackRequest = new Feedback_Request__c(Viewing1_Id__c=viewing1.Id,Contact__c = contact.Id);
        insert feedbackRequest;

        //when
        Feedback_Response__c response = new Feedback_Response__c();
        response.Property1__c = property.Id;
        response.Property1_Quality__c = 'Good';
        response.Member_experience__c = 7;
        response.Contact__c = contact.Id;
        response.Feedback_Request__c=feedbackRequest.Id;
        insert response;

        //then
        List<Customer_Feedback__c> feedbacks = [select id, Contact__c,Property__c, Property_Quality__c, Member_experience__c from Customer_Feedback__c];

        System.assertEquals(1, feedbacks.size());
        System.assertEquals(contact.Id, feedbacks.get(0).Contact__c);
        System.assertEquals(property.Id, feedbacks.get(0).Property__c);
        System.assertEquals('Good', feedbacks.get(0).Property_Quality__c);
        System.assertEquals(7, feedbacks.get(0).Member_experience__c);
    }
}