public with sharing class VirtualQuoteDocumentGenerator extends AbstractQuoteDocumentGenerator {

    public static final String LICENCE_AGREEMENT_DOCUMENT_NAME = 'Virtual Licence Agreement';
    public static final String DIRECT_DEBIT_DOCUMENT_NAME = 'Direct Debit Form';

    public override void updateAdditionalDocuments(SBQQ__Quote__c quote, Map<String, String> documentParams) {
        removePreviousDocumentVersion(quote, new Set<String>{
                LICENCE_AGREEMENT_DOCUMENT_NAME, DIRECT_DEBIT_DOCUMENT_NAME
        });
        generateNewLicenceAgreementDocument(quote, documentParams);
        generateNewDirectDebitDocument(quote);
    }

    private void generateNewLicenceAgreementDocument(SBQQ__Quote__c quote, Map<String, String> params) {
        //For signature process, Licence Agreement Document should be required for sending
        generateNewDocumentVersion(quote, Page.VirtualLicAgreementGenerator, LICENCE_AGREEMENT_DOCUMENT_NAME, params, 1, isDocumentRequired(params));
    }
}