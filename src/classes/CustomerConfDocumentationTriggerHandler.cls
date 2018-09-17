public with sharing class CustomerConfDocumentationTriggerHandler extends TriggerHandler {

    @TestVisible
    private final static String ERROR_MSG_THERE_CAN_ONLY_BE_ONE_MASTER = 'There can only be one master document per salesforce account per legal entity.';
    private CustomerConfidentialDocumentationService confidentialService = new CustomerConfidentialDocumentationService();

    public override void beforeInsert() {
        customValidationCDD(Trigger.new);
    }

    public override void beforeUpdate() {
        customValidationCDD(Trigger.new);
        List<Customer_Confidential_Documentation__c> signedForms = getSignedForms(Trigger.new, (Map<Id, Customer_Confidential_Documentation__c>) Trigger.oldMap);
        confidentialService.updateDirectDebitFormCompiledFields(signedForms);
        updateSignedDate(signedForms);
    }

    public override void afterUpdate() {
        generateAcknowledgementLetters(Trigger.new, Trigger.oldMap);
    }

    private List<Customer_Confidential_Documentation__c> getSignedForms(List<Customer_Confidential_Documentation__c> newForms, Map<Id, Customer_Confidential_Documentation__c> oldMap) {
        List<Customer_Confidential_Documentation__c> signedForms = new List<Customer_Confidential_Documentation__c>();
        for (Customer_Confidential_Documentation__c ddForm : newForms) {
            Customer_Confidential_Documentation__c oldForm = oldMap.get(ddForm.Id);
            if (oldForm.Signature_Status__c != ddForm.Signature_Status__c && ddForm.Signature_Status__c == 'Completed') {
                signedForms.add(ddForm);
            }
        }
        return signedForms;
    }

    private void updateSignedDate(List<Customer_Confidential_Documentation__c> signedForms) {
        for (Customer_Confidential_Documentation__c ddForm : signedForms) {
            ddForm.Date_Signed__c = Date.today();
        }
    }

    private static void customValidationCDD(List<Customer_Confidential_Documentation__c> newForms) {
        Set<Id> skipFormForValidation = new Set<Id>();
        Set<Id> accountIds = SObjectUtils.getIdSetFromObjects(newForms, 'Account__c');
        for (Customer_Confidential_Documentation__c ccd : newForms) {
            if (ccd.Id != null) {
                skipFormForValidation.add(ccd.Id);
            }
        }
        Set<String> masterCCDs = new Set<String>();
        for (Customer_Confidential_Documentation__c cdd : [
                SELECT Id, Account__c, Legal_Entity__c
                FROM Customer_Confidential_Documentation__c
                WHERE Master__c = TRUE
                AND Legal_Entity__c != null
                AND Account__c IN :accountIds
        ]) {
            if (!skipFormForValidation.contains(cdd.Id)) {
                masterCCDs.add('' + cdd.Account__c + cdd.Legal_Entity__c);
            }
        }
        for (Customer_Confidential_Documentation__c cdd : newForms) {
            if (cdd.Master__c && masterCCDs.contains('' + cdd.Account__c + cdd.Legal_Entity__c)) {
                cdd.Master__c.addError(ERROR_MSG_THERE_CAN_ONLY_BE_ONE_MASTER);
            }
        }
    }

    private void generateAcknowledgementLetters(List<Customer_Confidential_Documentation__c> docs, Map<Id, sObject> oldMap) {
        Set<Id> customerConfDocIds = new Set<Id>();
        for (Customer_Confidential_Documentation__c doc: docs) {
            Customer_Confidential_Documentation__c oldDoc = (Customer_Confidential_Documentation__c)oldMap.get(doc.Id);
            if (doc.Send_Customer_Acknowledgement_Letter__c && !oldDoc.Send_Customer_Acknowledgement_Letter__c) {
                customerConfDocIds.add(doc.Id);
            }
        }
        generateAcknowledgementLetter(customerConfDocIds);
    }

    @future
    public static void generateAcknowledgementLetter(Set<Id> customerConfDocIds) {
        Id templateId = EmailHelper.getEmailTemplateId('CCD_Customer_Acknowledgement');

        if (templateId != null && !customerConfDocIds.isEmpty()) {
            List<Attachment> attachments = new List<Attachment>();
            for (Id ccdId: customerConfDocIds) {
                Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(templateId, UserInfo.getUserId(), ccdId);

                for (Messaging.EmailFileAttachment emailFileAttachment : mail.getFileAttachments()) {
                    attachments.add(new Attachment(
                        Body = emailFileAttachment.getBody(),
                        Name = emailFileAttachment.getFileName(),
                        ParentId = ccdId)
                    );
                }
            }
            upsert attachments;
        }
    }
}