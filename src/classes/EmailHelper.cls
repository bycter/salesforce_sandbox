public without sharing class EmailHelper {

    public class EmailTemplateException extends Exception {
    }

    public static final String EMAIL_TEMPLATE_NOT_FOUND_ERROR_MSG = 'Email template not found. DeveloperName: ';

    public static final String QUOTE_ACCEPTED_ON_SAME_INVENTORY_EMAIL_TEMPLATE = 'Quote_Accepted_on_Same_Inventory';
    public static final String QUOTE_ACCEPTED_EMAIL_TEMPLATE = 'Quote_Accepted_Email_Template';
    public static final String QUOTE_UNLOCKED_EMAIL_TEMPLATE = 'Quote_Unlocked';
    public static final String FIT_OUT_NOTIFICATION_TO_PM_EMAIL_TEMPLATE = 'Fit_out_Notification_to_PM';

    @Future
    public static void sendEmailsToQuoteOwners(Set<Id> quoteIds, String templateName) {
        Map<Id, Id> opportunitiesOwnersIdsByQuoteIds = getOpportunityOwnerIdsByQuoteIds(quoteIds);
        List<SBQQ__Quote__c> quotes = [SELECT OwnerId FROM SBQQ__Quote__c WHERE Id = :opportunitiesOwnersIdsByQuoteIds.keySet()];
        Set<Id> ownersIds = SObjectUtils.getIdSetFromObjects(quotes, 'OwnerId');
        ownersIds.addAll(opportunitiesOwnersIdsByQuoteIds.values());
        Map<Id, Contact> contactsByOwnerIds = makeTempContactsFromUsers(ownersIds);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = getEmailTemplateId(templateName);
        for (SBQQ__Quote__c quote : quotes) {
            Id ownerId = opportunitiesOwnersIdsByQuoteIds.get(quote.Id);
            Id contactId = contactsByOwnerIds.get(ownerId).Id;
            Messaging.SingleEmailMessage mail = generateEmailMessage(templateId, contactId, quote.Id);
            mails.add(mail);
            if (quote.OwnerId != opportunitiesOwnersIdsByQuoteIds.get(quote.Id)) {
                contactId = contactsByOwnerIds.get(quote.OwnerId).Id;
                mail = generateEmailMessage(templateId, contactId, quote.Id);
                mails.add(mail);
            }
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails);
        delete contactsByOwnerIds.values();
    }

    @Future
    public static void sendEmailToUsers(Map<Id, Id> entityIdByUserId, String templateName) {
        Set<Id> usersIds = new Set<Id>(entityIdByUserId.values());
        Map<Id, Contact> contactsByUsersIds = makeTempContactsFromUsers(usersIds);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = getEmailTemplateId(templateName);
        for (Id entityId : entityIdByUserId.keySet()) {
            Id contactId = contactsByUsersIds.get(entityIdByUserId.get(entityId)).Id;
            Messaging.SingleEmailMessage mail = generateEmailMessage(templateId, contactId, entityId);
            mails.add(mail);
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails);
        delete contactsByUsersIds.values();
    }

    public static void sendEmailsToApprovers(Map<Id, List<ProcessInstanceWorkitem>> workItemsMappedByQuoteId, String templateName) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId = getEmailTemplateId(templateName);
        Set<Id> approversIds = new Set<Id>();
        for (Id quoteId : workItemsMappedByQuoteId.keySet()) {
            for (ProcessInstanceWorkitem workItem : workItemsMappedByQuoteId.get(quoteId)) {
                approversIds.add(workItem.OriginalActorId);
            }
        }
        Map<Id, Contact> contactsByApproverIds = makeTempContactsFromUsers(approversIds);
        for (Id quoteId : workItemsMappedByQuoteId.keySet()) {
            for (ProcessInstanceWorkitem workItem : workItemsMappedByQuoteId.get(quoteId)) {
                Contact cont = contactsByApproverIds.get(workItem.OriginalActorId);
                if (cont != null) {
                    Messaging.SingleEmailMessage mail = generateEmailMessage(templateId, cont.Id, quoteId);
                    mails.add(mail);
                }
            }
        }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mails);
        delete contactsByApproverIds.values();
    }

    private static Map<Id, Id> getOpportunityOwnerIdsByQuoteIds(Set<Id> quoteIds) {
        List<SBQQ__Quote__c> quotes = [SELECT Id, SBQQ__Opportunity2__r.OwnerId FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
        Map<Id, Id> opportunityOwnerIdsByQuoteIds = new Map<Id, Id>();
        for (SBQQ__Quote__c quote : quotes) {
            opportunityOwnerIdsByQuoteIds.put(quote.Id, quote.SBQQ__Opportunity2__r.OwnerId);
        }
        return opportunityOwnerIdsByQuoteIds;
    }

    public static Messaging.SingleEmailMessage generateEmailMessage(Id templateId, Id targetId, Id whatId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetId);
        mail.setSaveAsActivity(false);
        mail.setWhatId(whatId);
        return mail;
    }

    private static Map<Id, Contact> makeTempContactsFromUsers(Set<Id> usersIds) {
        Database.DMLOptions dml = new Database.DMLOptions();
        //Ignore duplication rules for saving
        dml.DuplicateRuleHeader.allowSave = true;
        dml.DuplicateRuleHeader.runAsCurrentUser = true;
        List<User> users = [SELECT Id, Email, FirstName, LastName FROM User WHERE Id IN :usersIds];
        Map<Id, Contact> contactsByUsersIds = new Map<Id, Contact>();
        for (User tempUser : users) {
            Contact tempContact = new Contact(
                    Email = tempUser.Email,
                    FirstName = tempUser.firstName,
                    LastName = tempUser.lastName,
                    Phone = '7788'); //Phone is defined to prevent duplication error
            contactsByUsersIds.put(tempUser.Id, tempContact);
        }
        Database.insert(contactsByUsersIds.values(), dml);
        return contactsByUsersIds;
    }

    public static Id getEmailTemplateId(String templateDeveloperName) {
        List<EmailTemplate> emailTemplates = [SELECT Id, Body, Subject, DeveloperName FROM EmailTemplate WHERE DeveloperName = :templateDeveloperName];

        EmailTemplate emailTemplate = null;
        if (emailTemplates.isEmpty()) {
            throw new EmailTemplateException(EMAIL_TEMPLATE_NOT_FOUND_ERROR_MSG + templateDeveloperName);
        } else {
            emailTemplate = emailTemplates.get(0);
        }
        return emailTemplate.Id;
    }
}