public with sharing class CustomerFeedbackTriggerHandler extends TriggerHandler {

    protected override void afterInsert() {
        linkViewingsToCustomerFeedbacks((List<Customer_Feedback__c>) Trigger.new);
        createTaskToBadViewing((List<Customer_Feedback__c>) Trigger.new);
    }

    private void createTaskToBadViewing(List<Customer_Feedback__c> newFeedbacks) {
        List<Customer_Feedback__c> feedbacks = new List<Customer_Feedback__c>();
        Set<Id> propertyIds = new Set<Id>();
        Set<Id> viewingsIds = new Set<Id>();
        for (Customer_Feedback__c feedback : newFeedbacks) {
            if (feedback.Property_Quality__c == Constants.PROPERTY_QUALITY_BAD) {
                feedbacks.add(feedback);
                propertyIds.add(feedback.Property__c);
                viewingsIds.add(feedback.Viewing_Id__c);
            }
        }

        if (!feedbacks.isEmpty()) {
            //Define Property_Manager__c related with Property__c
            Map<Id, Id> propertyToManager = new Map<Id, Id>();
            //Define Property Name
            Map<Id, String> propertyNames = new Map<Id, String>();
            for (Property__c pr : [SELECT Id, Property_Manager__c, Name FROM Property__c WHERE Id IN :propertyIds]) {
                propertyToManager.put(pr.Id, pr.Property_Manager__c);
                propertyNames.put(pr.Id, pr.Name);
            }
            //Define Property_Manager__c Name and Email
            Map<Id, User> userMap = new Map<Id, User>([
                    SELECT Name, Email
                    FROM User
                    WHERE Id IN :propertyToManager.values()
            ]);

            Map<Id, Event> viewingMap = new Map<Id, Event>([
                    SELECT Id, Subject, Viewing_Conducted_by_User__r.Name, StartDateTime
                    FROM Event
                    WHERE Id IN:viewingsIds
            ]);
            List<Task> tasksToAdd = new List<Task>();
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();

            for (Customer_Feedback__c feedback : feedbacks) {
                Event viewing = viewingMap.get(feedback.Viewing_Id__c);

                //Create a new task
                Task task = createTaskForCustomerFeedback(viewing, feedback, propertyToManager);
                tasksToAdd.add(task);

                String propertyName = propertyNames.get(feedback.Property__c);
                //Send an Email Notification to the Property Manager for a newly created Task
                mailList.add(createEmailNotificationForManager(task.OwnerId, viewing, feedback, userMap, propertyName));
            }

            if (!tasksToAdd.isEmpty()) {
                insert tasksToAdd;
                Messaging.sendEmail(mailList);
            }
        }
    }

    private Task createTaskForCustomerFeedback(Event viewing, Customer_Feedback__c feedback, Map<Id, Id> propertyToManager) {
        Task task = new Task();
        task.Subject = 'Negative Feedback';
        if (propertyToManager.containsKey(feedback.Property__c)) {
            task.OwnerId = propertyToManager.get(feedback.Property__c);
        }
        task.Description = 'Please note that negative feedback has been received after a viewing has taken place.\n' +
                'Please assess the feedback and take any necessary actions.\n' +
                'Please change the status of the task to \'Complete\' when you feel the issue has been rectified.';
        task.Property__c = feedback.Property__c;
        task.WhatId = feedback.Id;
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.Customer_Feedback__c = feedback.Id;
        task.Viewing_Id__c = viewing.Id;
        task.Viewing_Name__c = viewing.Subject;
        return task;
    }

    private Messaging.SingleEmailMessage createEmailNotificationForManager(Id ownerId, Event viewing, Customer_Feedback__c feedback, Map<Id, User> userMap, String propertyName) {
        User theUser = userMap.get(ownerId);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[]{
                theUser.Email
        };
        //Define the date format
        DateTime dT = viewing.StartDateTime;
        Date myDate = Date.newInstance(dT.year(), dT.month(), dT.day());

        message.setToAddresses(toAddresses);
        message.setSubject('Negative Feedback');
        String body = '<p>Please note that <a href=' + system.URL.getSalesforceBaseUrl().toExternalForm() + '/'
                + feedback.Property__c + ' >' + propertyName + '</a> has received some negative feedback after a viewing has taken place.</p>';
        body += '<p>A task has been created for you to assess the feedback and take any necessary actions. ';
        body += 'Please change the status of the task to \'Complete\' when you feel the issue has been rectified.</p>';
        body += '<p>Viewing Conducted by: ' + viewing.Viewing_Conducted_by_User__r.Name + '<br>';
        body += 'Viewing: <a href=' + system.URL.getSalesforceBaseUrl().toExternalForm() + '/'
                + viewing.Id + ' >' + viewing.Subject + '</a><br>';
        body += 'Viewing Date: ' + myDate.format() + '<br>';
        body += 'Feedback: <a href=' + system.URL.getSalesforceBaseUrl().toExternalForm() + '/'
                + feedback.Id + ' >' + feedback.Name + '</a></p>';
        message.setHtmlBody(body);
        return message;
    }

    private void linkViewingsToCustomerFeedbacks(List<Customer_Feedback__c> newFeedbacks) {
        Map<Id, Id> viewingFeedbackIdsMap = new Map<Id, Id>();
        for (Customer_Feedback__c customerFeedback : newFeedbacks) {
            viewingFeedbackIdsMap.put(customerFeedback.Viewing_Id__c, customerFeedback.Id);
        }

        List<Event> viewings = [SELECT Id, Customer_Feedback__c FROM Event WHERE Id IN :viewingFeedbackIdsMap.keySet()];

        for (Event viewing : viewings) {
            viewing.Customer_Feedback__c = viewingFeedbackIdsMap.get(viewing.Id);
        }

        update viewings;
    }
}