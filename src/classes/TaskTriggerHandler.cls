public class TaskTriggerHandler extends TriggerHandler {

    static final String NEW_TASK_TO_USER_TEMPLATE_DEVELOPER_NAME = 'New_Task_to_User';
    static final String BANKING_CONSENT_TASK_SUBJECT_PART = 'Banking Consent';
    static final String HEAD_LANDLORD_CONSENT_TASK_SUBJECT_PART = 'Head Landlord Consent';

    public override void beforeInsert() {
        populateCasePropertyAndInventoryInTasks(Trigger.new);
    }

    public override void afterInsert() {
        sendEmailsToConsentTaskOwners(Trigger.new);
    }

    public override void afterUpdate() {
        updateRelatedQuotesWithPayByBACsStatus(Trigger.new);
        acceptQuotesForCompletedTasks(Trigger.new);
        updateRelatedOpportunities(Trigger.new);
    }

    private void sendEmailsToConsentTaskOwners(List<Task> tasks) {
        List<Task> consentTasks = findConsentTasks(tasks);
        sendEmailsToAssignee(consentTasks, NEW_TASK_TO_USER_TEMPLATE_DEVELOPER_NAME);
    }

    private void populateCasePropertyAndInventoryInTasks(List<Task> tasks) {
        Map<Id, Case> casesByIds = getCasesByIdsFromWhatIds(tasks);
        for (Task theTask : tasks) {
            if (casesByIds.containsKey(theTask.WhatId)) {
                Case relatedCase = casesByIds.get(theTask.WhatId);
                theTask.Inventory__c = relatedCase.Inventory__c;
                theTask.Property__c = relatedCase.Property__c;
            }
        }
    }

    private Map<Id, Case> getCasesByIdsFromWhatIds(List<Task> tasks) {
        Set<Id> casesIds = new Set<Id>();
        for (Task theTask : tasks) {
            if (theTask.WhatId != null && theTask.WhatId.getSobjectType() == Case.getSObjectType()) {
                casesIds.add(theTask.WhatId);
            }
        }
        Map<Id, Case> casesByIds = new Map<Id, Case>([SELECT Id, Inventory__c, Property__c FROM Case WHERE Id IN :casesIds]);
        return casesByIds;
    }

    private List<Task> findConsentTasks(List<Task> tasks) {
        List<Task> result = new List<Task>();
        result.addAll(findTasksWhichSubjectContainsText(Trigger.new, BANKING_CONSENT_TASK_SUBJECT_PART));
        result.addAll(findTasksWhichSubjectContainsText(Trigger.new, HEAD_LANDLORD_CONSENT_TASK_SUBJECT_PART));
        return result;
    }

    private List<Task> findTasksWhichSubjectContainsText(List<Task> tasks, String text) {
        List<Task> result = new List<Task>();
        for (Task task : tasks) {
            if (task.Subject != null && task.Subject.contains(text)) {
                result.add(task);
            }
        }
        return result;
    }

    private void sendEmailsToAssignee(List<Task> tasks, String templateName) {
        EmailTemplate emailTemplate = [SELECT Id, Body, Subject FROM EmailTemplate WHERE DeveloperName = :templateName];
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for (Task task : tasks) {
            Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(emailTemplate.Id, task.OwnerId, task.Id);

            String emailSubject = mail.getSubject();
            String emailTextBody = mail.getPlainTextBody();

            mail.setTargetObjectId(task.OwnerId);
            mail.setSubject(emailSubject);
            mail.setPlainTextBody(emailTextBody);
            mail.setSaveAsActivity(false);
            mails.add(mail);
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails);
    }

    private List<Task> filterTasksByStatus(Map<Id, Task> oldMap, List<Task> tasks, String status, Boolean checkStatusUpdate) {
        List<Task> filteredTasks = new List<Task>();
        for (Task newTask : tasks) {
            Task oldTask = oldMap.get(newTask.Id);
            Boolean addTask = (checkStatusUpdate && oldTask.Status != newTask.Status && newTask.Status == status) ||
                                (!checkStatusUpdate && newTask.Status == status);
            if ( addTask ) {
                filteredTasks.add(newTask);
            }
        }
        return filteredTasks;
    }

    private List<Task> filterTasksByStatus(List<Task> tasks, String status) {
        return filterTasksByStatus((Map<Id, Task>)Trigger.oldMap, tasks, status, false);
    }

    private List<Task> filterTasksBySystemCode(List<Task> tasks, String systemCode) {
        List<Task> filteredTasks = new List<Task>();
        for (Task task : tasks) {
            if (task.System_Code__c == systemCode) {
                filteredTasks.add(task);
            }
        }
        return filteredTasks;
    }

    private Set<Id> obtainWhatIds(List<Task> tasks) {
        Set<Id> whatIds = new Set<Id>();
        for (Task task : tasks) {
            if (task.WhatId != null) {
                whatIds.add(task.WhatId);
            }
        }
        return whatIds;
    }

    private void updateRelatedQuotesWithPayByBACsStatus(List<Task> tasks) {
        List<Task> payByBacsTasks = filterTasksBySystemCode(tasks, TaskService.PAY_BY_BACS_SYSTEM_CODE);
        Set<Id> whatIdsRelatedToCompletedTasks = obtainWhatIds(filterTasksByStatus(payByBacsTasks, 'Completed'));
        Set<Id> whatIdsRelatedToRejectedTasks = obtainWhatIds(filterTasksByStatus(payByBacsTasks, 'Rejected'));

        //If tasks are completed, PayByBACs will be approved
        updateQuotesWithPayByBACsStatus([SELECT Id FROM SBQQ__Quote__c WHERE Id IN :whatIdsRelatedToCompletedTasks], true, false);

        //If tasks are rejected, PayByBACs will be also rejected
        updateQuotesWithPayByBACsStatus([SELECT Id FROM SBQQ__Quote__c WHERE Id IN :whatIdsRelatedToRejectedTasks], false, true);
    }

    private void updateQuotesWithPayByBACsStatus(List<SBQQ__Quote__c> quotes, Boolean approvedStatus, Boolean rejectedStatus) {
        for (SBQQ__Quote__c quote : quotes) {
            quote.Pay_by_BACs_Approved__c = approvedStatus;
            quote.Pay_by_BACs_Rejected__c = rejectedStatus;
        }
        update quotes;
    }

    private void acceptQuotesForCompletedTasks(List<Task> tasks) {
        List<Task> setupCDTasks = filterTasksBySystemCode(tasks, TaskService.SETUP_CD_SYSTEM_CODE);
        Set<Id> quoteIdsForAcceptance = obtainWhatIds(filterTasksByStatus((Map<Id, Task>)Trigger.oldMap, setupCDTasks, 'Completed', true));
        Map<Id, String> quoteStatusesMap = new Map<Id, String>();
        for ( Id quoteId : quoteIdsForAcceptance ) {
            quoteStatusesMap.put(quoteId, SBQQ_QuoteConstants.STATUS_ACCEPTED);
        }
        SBQQ_QuoteService.updateQuotesStatuses(quoteStatusesMap);
        List<SBQQ__Quote__c> acceptedQuotes = [SELECT SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id IN :quoteIdsForAcceptance];
        Set<Id> oppIds = SObjectUtils.getIdSetFromObjects(acceptedQuotes, 'SBQQ__Opportunity2__c');
        List<Opportunity> opportunitiesForUpdate = new List<Opportunity>();
        for ( Id oppId : oppIds ) {
            opportunitiesForUpdate.add(new Opportunity(Id = oppId, Force_Status_Recalculation__c = true));
        }
        update opportunitiesForUpdate;
    }

    private void updateRelatedOpportunities(List<Task> tasks) {
        List<Task> standardTasks = (List<Task>)SObjectUtils.filterRecordsByRecordType(tasks, new Set<Id> { TaskService.STANDARD_TASK_TYPE_ID });
        List<Task> completedTasks = filterTasksByStatus((Map<Id, Task>)Trigger.oldMap, standardTasks, 'Completed', true);
        List<Opportunity> toUpdate = new List<Opportunity>();
        for (Task completed: completedTasks) {
            if (completed.Type == TaskService.TYPE_VIRTUAL_ONBOARDING && completed.Subject == TaskService.SUBJECT_VIRTUAL_CUSTOMER_ID && 
                completed.Opportunity__c != null) {
                toUpdate.add(new Opportunity(
                    Id = completed.Opportunity__c,
                    Virtual_Check_Completed__c = true
                ));
            }
        }
        update toUpdate;
    }
}