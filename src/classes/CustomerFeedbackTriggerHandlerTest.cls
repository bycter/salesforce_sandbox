@IsTest
private class CustomerFeedbackTriggerHandlerTest {
    @isTest static void createTaskRelatedWithCustomerFeedback() {
        User testUser = RecordDmlTest.createUser('bwstandarduser', 'BW Standard User');
        insert testUser;

        Product2 p2 = new Product2(Name='Test Product',isActive=true);
        Database.insert(p2);

        Property__c property = RecordDmlTest.createProperty();
        property.Name = 'Hatch';
        update property;

        Contact contact = new Contact(LastName = 'Last Name', Email = 'testBW@test.com');
        insert contact;
        Id recordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Viewing').getRecordTypeId();
        Event event = new Event(
                RecordTypeId = recordTypeId,
                Property__c = property.Id,
                Status__c = 'Booked',
                Viewing_Arranged_by__c = 'Sales',
                Viewing_Conducted_by__c = 'Sales',
                OwnerId = testUser.Id,
                WhoId = contact.Id,
                WhatId = RecordDmlTest.createOpportunity('Conventional').Id,
                Viewing_Conducted_by_User__c = RecordDmlTest.createUser().Id,
                StartDateTime = Date.today().addDays(1),
                EndDateTime = Date.today().addDays(2));
        insert event;

        Customer_Feedback__c feedback = new Customer_Feedback__c();
        feedback.Name = 'Test Bad Feedback';
        feedback.Property_Quality__c = Constants.PROPERTY_QUALITY_BAD;
        feedback.Member_experience__c = 7;
        feedback.Contact__c = contact.Id;
        feedback.Property__c = property.Id;
        feedback.Viewing_Id__c = event.Id;
        insert feedback;

        List<Task> tasks = [SELECT Id, WhatId, Property__c, OwnerId, Customer_Feedback__c FROM Task];
        List<Event> events = [SELECT Id, WhatId, Property__c, OwnerId, Customer_Feedback__c FROM Event];

        System.assertEquals(feedback.Id, tasks.get(0).WhatId);
        System.assertEquals(feedback.Property__c, tasks.get(0).Property__c);
        System.assertEquals(property.Property_Manager__c, tasks.get(0).OwnerId);
        System.assertEquals(feedback.Id, tasks.get(0).Customer_Feedback__c);
        System.assertEquals(feedback.Id, events.get(0).Customer_Feedback__c);
    }
}