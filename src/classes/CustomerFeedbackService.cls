public with sharing class CustomerFeedbackService {

    public static void createFeedbacks(List<Feedback_Response__c> responses) {
        Set<Id>feedbackRequestIds = SObjectUtils.getIdSetFromObjects(responses, 'Feedback_Request__c');
        Map<Id, Feedback_Request__c> requestsMap = new Map<Id, Feedback_Request__c>([
            SELECT Id, Lead__c, Lead__r.Name, Contact__c, Contact__r.Name, 
                Viewing1_Id__c, Viewing2_Id__c, Viewing3_Id__c, Viewing4_Id__c, Viewing5_Id__c,
                Viewing6_Id__c, Viewing7_Id__c, Viewing8_Id__c, Viewing9_Id__c, Viewing10_Id__c
            FROM Feedback_Request__c
            WHERE Id in:feedbackRequestIds
        ]);

        Set<Id> propertyIds = new Set<Id>();
        Set<Id> viewingsIds = new Set<Id>();

        for (Feedback_Response__c response : responses) {
            Feedback_Request__c request = requestsMap.get(response.Feedback_Request__c);
            request = request == null ? new Feedback_Request__c() : request;

            for (Integer i = 1; i <= ScheduledViewingFeedbackEmailSending.MAXIMUM_VIEWINGS_IN_SESSION; i++) {
                Id propertyId = (Id) response.get('Property' + i + '__c');
                Id viewingId = (Id) request.get('Viewing' + i + '_Id__c');

                if (propertyId != null) {
                    propertyIds.add(propertyId);
                    viewingsIds.add(viewingId);
                } else {
                    break;//no more viewings
                }
            }
        }

        Map<Id, Property__c> propertiesMap = new Map<Id, Property__c>([SELECT Id, Name FROM Property__c WHERE Id IN: propertyIds]);
        Map<Id, Event> viewingsMap = new Map<id, Event>([SELECT Id, WhatId FROM Event WHERE id in :viewingsIds]);
        Set<Id> potentialOpportunitiesIds = SObjectUtils.getIdSetFromObjects(viewingsMap.values(), 'WhatId');
        Set<Id> opportunitiesIds = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE id in :potentialOpportunitiesIds]).keySet();

        List<Customer_Feedback__c> feedbacks = new List<Customer_Feedback__c>();
        for (Feedback_Response__c response : responses) {
            Feedback_Request__c request = requestsMap.get(response.Feedback_Request__c);
            request = request == null ? new Feedback_Request__c() : request;
            Decimal teamMemberExperience = response.Member_Experience__c;
            String feedbackText = response.Feedback__c;
            String commentText = response.Comments__c;

            for (Integer i = 1; i <= ScheduledViewingFeedbackEmailSending.MAXIMUM_VIEWINGS_IN_SESSION; i++) {
                Id propertyId = (Id) response.get('Property' + i + '__c');
                Id viewingId = (Id) request.get('Viewing' + i + '_Id__c');
                String propertyQuality = (String) response.get('Property' + i + '_Quality__c');

                if (propertyId != null && propertyQuality != null && viewingId != null) {
                    Customer_Feedback__c customerFeedback = CustomerFeedbackService.createCustomerFeedback(propertyId, propertyQuality, viewingId, teamMemberExperience, request.Contact__c, request.Lead__c);
                    customerFeedback.Name = propertiesMap.get(propertyId).Name + '-' + (request.Contact__c != null ? request.Contact__r.Name : request.Lead__r.Name);
                    customerFeedback.Comment__c = commentText;
                    customerFeedback.Feedback__c = feedbackText;
                    // add opportunity
                    Id potentialOpportunityId = viewingsMap.get(viewingId).WhatId;
                    if (opportunitiesIds.contains(potentialOpportunityId)) {
                        customerFeedback.Opportunity__c = potentialOpportunityId;
                    }
                    feedbacks.add(customerFeedback);
                } else {
                    break;//no more viewings
                }
            }
        }

        insert feedbacks;
    }

    public static Customer_Feedback__c createCustomerFeedback(Id propertyId, String quality, Id viewingId, Decimal teamMemberExperience, Id contactId, Id leadId) {
        Customer_Feedback__c customerFeedback = new Customer_Feedback__c(
                Property_Quality__c = quality,
                Property__c = propertyId,
                Member_Experience__c = teamMemberExperience,
                Contact__c = contactId,
                Lead__c = leadId,
                Viewing_Id__c = viewingId
        );
        return customerFeedback;
    }
}