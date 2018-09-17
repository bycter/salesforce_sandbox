public with sharing class TaskService {
    public static final String PRIORITY_NORMAL = 'Normal';
    public static final String STATUS_OPEN = 'Open';
    public static final String TYPE_VIRTUAL_ONBOARDING = 'Virtual Customer on-boarding';
    public static final String TYPE_OTHER = 'Other';

    public static final String SUBJECT_SETUP_CD = 'Setup Director Contact';
    public static final String SUBJECT_REVIEW_PC = 'Please review new/updated contact on the Quote';
    public static final String SUBJECT_VIRTUAL_CUSTOMER_ID = 'Virtual Customer ID';
    public static final String SUBJECT_REVIEW_SUITE_CONDITION = 'Please review suite condition. Negative feedback recieved';

    public static final String PAY_BY_BACS_SYSTEM_CODE = 'PayByBACs';
    public static final String SETUP_CD_SYSTEM_CODE = 'SetupCD';
    public static final String REVIEW_POTENTIAL_CONTACT_SYSTEM_CODE = 'ReviewPC';

    public static final Id STANDARD_TASK_TYPE_ID;
    static {
        STANDARD_TASK_TYPE_ID = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Standard Task').getRecordTypeId();
    }

    public static Task generateVirtualMeetingTask(Opportunity theOpportunity, Event theEvent) {
        return new Task(
                Priority = PRIORITY_NORMAL,
                Status = STATUS_OPEN,
                Type = TYPE_VIRTUAL_ONBOARDING,
                Subject = SUBJECT_VIRTUAL_CUSTOMER_ID,
                RecordTypeId = STANDARD_TASK_TYPE_ID,

                OwnerId = theEvent.Property__r.Serviced_Space_Coordinator__c,
                Opportunity__c = theOpportunity.Id, // Opportunity Name
                Property__c = theEvent.Property__c, // Property Name
                Description = theOpportunity.Briefing_Statement__c,
                WhoId = theEvent.WhoId, // Sales Contact
                WhatId = theOpportunity.AccountId // Account Name
        );
    }

    public static Task generateVirtualTask(Opportunity theOpportunity, SBQQ__Quote__c quote) {
        return new Task(
                Priority = PRIORITY_NORMAL,
                Status = STATUS_OPEN,
                Type = TYPE_VIRTUAL_ONBOARDING,
                RecordTypeId = STANDARD_TASK_TYPE_ID,

                Subject = quote.SBQQ__PrimaryContact__r.Name + ': New Virtual Customer to be on-boarded',
                OwnerId = quote.Property__r.Serviced_Space_Coordinator__c,
                Property__c = quote.Property__c, // Property Name
                Description = theOpportunity.Briefing_Statement__c,
                WhoId = quote.SBQQ__PrimaryContact__c, // Primary Contact
                WhatId = theOpportunity.AccountId, // Customer
                ActivityDate = quote.Contract__c != null ? quote.Contract__r.StartDate : null
        );
    }

    public static Task generateSetupCDTask(SBQQ__QuoteDocument__c theDocument) {
        return new Task(
            Priority = PRIORITY_NORMAL,
            Status = STATUS_OPEN,
            Type = TYPE_OTHER,
            Subject = SUBJECT_SETUP_CD,
            RecordTypeId = STANDARD_TASK_TYPE_ID,

            OwnerId = theDocument.Opportunity_Owner_Id__c,
            WhatId = theDocument.SBQQ__Quote__c,
            System_Code__c = SETUP_CD_SYSTEM_CODE
        );
    }

    public static Task generateReviewPCTask(Id ownerId, Id potentialContactId) {
        return new Task(
            Subject = SUBJECT_REVIEW_PC,
            WhatId = potentialContactId,
            Priority = PRIORITY_NORMAL,
            Status = STATUS_OPEN,
            Type = TYPE_OTHER,
            OwnerId = ownerId,
            RecordTypeId = STANDARD_TASK_TYPE_ID,
            System_Code__c = REVIEW_POTENTIAL_CONTACT_SYSTEM_CODE
        );
    }

    public static Task generatePropertyManagerNotification(Event theEvent, Id propertyManagerId, String suiteConditionComments) {
        return new Task(
            Priority = PRIORITY_NORMAL,
            Status = STATUS_OPEN,
            Type = TYPE_OTHER,
            Subject = SUBJECT_REVIEW_SUITE_CONDITION,
            RecordTypeId = STANDARD_TASK_TYPE_ID,

            Property__c = theEvent.Property__c,
            WhatId = theEvent.Property__c,
            Viewing_Id__c = theEvent.Id,
            Viewing_Name__c = theEvent.Subject,
            OwnerId = propertyManagerId,
            Description = suiteConditionComments
        );
    }
}