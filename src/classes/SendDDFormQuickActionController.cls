public with sharing class SendDDFormQuickActionController {

    private static final Quote_Template_Settings__c TEMPLATE_SETTINGS = Quote_Template_Settings__c.getOrgDefaults();
    private static final String DEFAULT_SUBJECT = 'Please DocuSign: Direct Debit Form';

    private static final String AC_DD_FORM_TEMPLATE_ID { get; set; }

    static {
        AC_DD_FORM_TEMPLATE_ID = TEMPLATE_SETTINGS.Ad_Hoc_Direct_Debit_Form_Template_Id__c;
    }

    @AuraEnabled
    public static void sendDDForm(Id recordId, Id contactId, Id accountId, String emailBody) {
        Customer_Confidential_Documentation__c ddForm = [SELECT SBQQ_Quote_Document__r.SBQQ__Quote__r.Property__r.Direct_Debit_Form_Developer_Name__c, Account__c,
                                                                Legal_Entity__r.Direct_Debit_Form_Developer_Name__c
                                                         FROM Customer_Confidential_Documentation__c
                                                         WHERE Id = :recordId];
        if ( ddForm.SBQQ_Quote_Document__c == null && ddForm.Legal_Entity__c == null ) {
            throw new AuraHandledException('Please populate Legal Entity on the record');
        }
        Contact selectedContact = [SELECT Name, Email FROM Contact WHERE Id = :contactId];
        String ddFormDeveloperName = String.isNotBlank(ddForm.SBQQ_Quote_Document__r.SBQQ__Quote__r.Property__r.Direct_Debit_Form_Developer_Name__c) ? ddForm.SBQQ_Quote_Document__r.SBQQ__Quote__r.Property__r.Direct_Debit_Form_Developer_Name__c : ddForm.Legal_Entity__r.Direct_Debit_Form_Developer_Name__c;
        if ( String.isBlank(ddFormDeveloperName) ) {
            throw new AuraHandledException('Please specify Direct Debit Form Developer Name on Legal Entity record');
        }
        List<Document> documents = [SELECT Name FROM Document WHERE DeveloperName = :ddFormDeveloperName LIMIT 1];
        if ( !documents.isEmpty() ) {
            ddForm.Account__c = ddForm.Account__c == null ? accountId : ddForm.Account__c;
            ddForm.Signature_Status__c = 'Pending';
            String envelopeId = DocuSignIntegrator.sendEnvelope(selectedContact.Name, selectedContact.Email, DEFAULT_SUBJECT, emailBody, AC_DD_FORM_TEMPLATE_ID, documents[0].Name, documents[0].Id, recordId);
            ddForm.Envelope_Id__c = envelopeId;
            ddForm.OwnerId = UserInfo.getUserId();
            ddForm.Direct_Debit_Signature__c = contactId;
            update ddForm;
        }
    }
}