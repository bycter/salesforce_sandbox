public with sharing class SBQQ_QuoteDocumentTriggerHandler extends TriggerHandler {

    private SBQQ_QuoteDocumentService theDocumentService = new SBQQ_QuoteDocumentService();
    private PotentialContactService thePotentialContactService = new PotentialContactService();
    private ContactService theContactService = new ContactService();
    private AccountService theAccountService = new AccountService();

    public override void beforeInsert() {
        prepopulateCustomerContactsFields(Trigger.new);
        prepopulateCustomerRegistrationNumber(Trigger.new);
        theDocumentService.populateUniqueDocumentsNumber(Trigger.new);
    }

    public override void afterInsert() {
        List<SBQQ__QuoteDocument__c> documents = (List<SBQQ__QuoteDocument__c>) Trigger.new;
        updateQuoteStatusWithPresented(documents);
    }

    public override void beforeUpdate() {
        syncSignatureStatusFields(Trigger.new);
        moveDirectDebitFormFieldsToSecureObject((Map<Id, SBQQ__QuoteDocument__c>)Trigger.oldMap, Trigger.new);
        verifyIfDocumentsSignedByCompanyDirector((Map<Id, SBQQ__QuoteDocument__c>)Trigger.oldMap, Trigger.new);
    }

    public override void afterUpdate() {
        Map<SBQQ__QuoteDocument__c, Set<String>> updatedDocumentsMap = theDocumentService.getDocumentsWithUpdatedContactInfo((Map<Id, SBQQ__QuoteDocument__c>)Trigger.oldMap, Trigger.new);
        thePotentialContactService.createPotentialContactsForUpdatedDocuments(updatedDocumentsMap, (Map<Id, SBQQ__QuoteDocument__c>)Trigger.oldMap);
        updateCompanyRegistrationNumbers((Map<Id, SBQQ__QuoteDocument__c>)Trigger.oldMap, Trigger.new);
        theDocumentService.updateParentOpportunities(Trigger.new);
    }

    private void prepopulateCustomerContactsFields(List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<Id, Id> quoteToAccountMap = theDocumentService.getRelatedAccountIdsMap(quoteDocuments);
        Map<Id, List<Contact>> contactsMap = theContactService.getCustomerContactsMap(new Set<Id>(quoteToAccountMap.values()));
        for ( SBQQ__QuoteDocument__c theDocument : quoteDocuments ) {
            theDocumentService.populateQuoteDocumentFields(theDocument, contactsMap.get(quoteToAccountMap.get(theDocument.SBQQ__Quote__c)));
        }
    }

    private void prepopulateCustomerRegistrationNumber(List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<Id, Id> quoteToAccountMap = theDocumentService.getRelatedAccountIdsMap(quoteDocuments);
        Map<Id, Account> relatedAccountsMap = new Map<Id, Account>([SELECT Company_Registration_Number__c FROM Account WHERE Id IN :quoteToAccountMap.values()]);
        for ( SBQQ__QuoteDocument__c theDocument : quoteDocuments ) {
            theDocument.Company_Registration_Number__c = relatedAccountsMap.get(theDocument.Account_Id__c).Company_Registration_Number__c;
        }
    }

    private void updateCompanyRegistrationNumbers(Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap, List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<Id, String> accountIdToCompanyNumberMap = theDocumentService.getAccountIdsWithUpdatedCompanyNumber(oldDocumentsMap, quoteDocuments);
        theAccountService.updateCompanyRegistrationNumbers(accountIdToCompanyNumberMap);
    }

    private void verifyIfDocumentsSignedByCompanyDirector(Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap, List<SBQQ__QuoteDocument__c> quoteDocuments) {
        List<SBQQ__QuoteDocument__c> servicedDocuments = theDocumentService.getDocumentsWithRecordType(quoteDocuments, SBQQ_QuoteConstants.SERVICED_RECORD_TYPE);
        Map<Id, SBQQ__QuoteDocument__c> signedDocumentsMap = theDocumentService.getSignedDocumentsMap(servicedDocuments);
        Set<Id> accountIds = new Set<Id>();
        for ( SBQQ__QuoteDocument__c theDocument : signedDocumentsMap.values() ) {
            SBQQ__QuoteDocument__c oldDocument = oldDocumentsMap.get(theDocument.Id);
            if ( oldDocument.SBQQ__SignatureStatus__c != theDocument.SBQQ__SignatureStatus__c ) {
                accountIds.add(theDocument.Account_Id__c);
            }
        }
        Map<Id, List<Contact>> companyDirectorsMap = theContactService.getCompanyDirectorsMap(accountIds);
        theDocumentService.verifyIfDocumentsSignedByCompanyDirector(signedDocumentsMap.values(), companyDirectorsMap);
    }

    private void moveDirectDebitFormFieldsToSecureObject(Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap, List<SBQQ__QuoteDocument__c> quoteDocuments) {
        CustomerConfidentialDocumentationService ccdService = new CustomerConfidentialDocumentationService();
        Map<Id, SBQQ__QuoteDocument__c> signedDocumentsMap = theDocumentService.getSignedDocumentsMap(quoteDocuments);
        List<SBQQ__QuoteDocument__c> signedSecureDocuments = new List<SBQQ__QuoteDocument__c>();
        for ( SBQQ__QuoteDocument__c theDocument : signedDocumentsMap.values() ) {
            SBQQ__QuoteDocument__c oldDocument = oldDocumentsMap.get(theDocument.Id);
            if ( oldDocument.SBQQ__SignatureStatus__c != theDocument.SBQQ__SignatureStatus__c && String.isNotBlank(theDocument.DDF_Acc_Num_1__c) &&
                    (theDocument.Quote_Record_Type__c.startsWith('Serviced') || theDocument.Quote_Record_Type__c.startsWith('Virtual') )) {
                signedSecureDocuments.add(theDocument);
            }
        }
        ccdService.moveDirectDebitFormFieldsToSecureObject(signedSecureDocuments);
    }

    private void updateQuoteStatusWithPresented(List<SBQQ__QuoteDocument__c> documents) {
        Set<Id> quotesIds = new Set<Id>();
        for (SBQQ__QuoteDocument__c document : documents) {
            if (document.SBQQ__Quote__c != null && document.SBQQ__ElectronicSignature__c && document.Update_Quote_Status__c) {
                quotesIds.add(document.SBQQ__Quote__c);
            }
        }
        List<SBQQ__Quote__c> quotes = updateQuotesWithSpecifiedStatus([SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id IN :quotesIds], 'Presented');
        update quotes;
    }

    private List<SBQQ__Quote__c> updateQuotesWithSpecifiedStatus(List<SBQQ__Quote__c> quotes, String status) {
        for (SBQQ__Quote__c quote : quotes) {
            quote.SBQQ__Status__c = status;
        }
        return quotes;
    }

    private void syncSignatureStatusFields(List<SBQQ__QuoteDocument__c> newDocuments) {
        for ( SBQQ__QuoteDocument__c theDocument : newDocuments ) {
            theDocument.SBQQ__SignatureStatus__c = theDocument.Signature_Status__c;
        }
    }

}