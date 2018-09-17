public abstract class AbstractQuoteDocumentGenerator extends QuoteVisualforceDocumentGenerator implements QuoteDocumentGenerator {

    public static final String CAR_PARKING_DOCUMENT_NAME = 'Car Parking Licence Document';
    public static final String DIRECT_DEBIT_DOCUMENT_NAME = 'Direct Debit Form';

    public abstract void updateAdditionalDocuments(SBQQ__Quote__c quote, Map<String, String> documentParams);

    public void updateAdditionalDocuments(SBQQ__Quote__c quote) {
        updateAdditionalDocuments(quote, new Map<String, String>());
    }

    protected SBQQ__RelatedContent__c generateNewDocumentVersion(SBQQ__Quote__c quote, Id documentId, String documentName) {
        return generateNewDocumentVersion(quote, documentId, documentName, 0);
    }

    protected SBQQ__RelatedContent__c generateNewDocumentVersion(SBQQ__Quote__c quote, Id documentId, String documentName, Integer order) {
        SBQQ__RelatedContent__c quoteDocument = new SBQQ__RelatedContent__c(Name = documentName, SBQQ__ExternalId__c = documentId, SBQQ__Quote__c = quote.Id, SBQQ__DisplayOrder__c = order);
        insert quoteDocument;
        return quoteDocument;
    }

    protected void removePreviousDocumentVersion(SBQQ__Quote__c quote, Set<String> documentNames) {
        for (String documentName : documentNames) {
            documentName += documentName + '.pdf';
        }
        delete [SELECT Id FROM Attachment WHERE parentId = :quote.Id AND Name IN :documentNames];
        delete [SELECT Id FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name IN :documentNames];
    }

    protected Boolean isSignatureProcess(Map<String, String> params) {
        if (params.containsKey(QuoteDocumentParams.SEND_FOR_KEY_NAME)) {
            return params.get(QuoteDocumentParams.SEND_FOR_KEY_NAME) == QuoteDocumentParams.SIGNATURE;
        }
        return false;
    }

    protected Boolean isOfflineDocumentSending(Map<String, String> params) {
        if (params.containsKey(QuoteDocumentParams.SEND_OFFLINE_DOCUMENT)) {
            return params.get(QuoteDocumentParams.SEND_OFFLINE_DOCUMENT) == QuoteDocumentParams.SEND_OFFLINE_DOCUMENT;
        }
        return false;
    }

    protected Boolean isDocumentRequired(Map<String, String> params){
        return !isOfflineDocumentSending(params) && isSignatureProcess(params);
    }

    protected void generateCarParkingLicenceDocument(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> lines, Map<String, String> params, Integer order, Boolean required) {
        //Car Parking Licence Document should be generated only if Car Parking Licence is added
        if (SBQQ_QuoteService.isHeadLineProductAdded(lines, QuoteProductCodes.CAR_PARKING_LICENSE)) {
            generateNewDocumentVersion(quote, Page.CarParkingLicenceDocumentGenerator, CAR_PARKING_DOCUMENT_NAME, params, order, required);
        }
    }

    protected void generateNewDirectDebitDocument(SBQQ__Quote__c quote) {
        // Direct Debit form should be generated only if Pay by BACs option isn't selected.
        // If Pay by BACs option is selected and approved, a customer will not pay trough Direct Debit form.
        if (quote.Property__c != null && !(quote.Pay_by_BACs__c && quote.Pay_by_BACs_Approved__c)) {
            Property__c property = [SELECT Id, Direct_Debit_Form_Developer_Name__c FROM Property__c WHERE Id = :quote.Property__c];
            List<Document> documents = [SELECT Id FROM Document WHERE DeveloperName = :property.Direct_Debit_Form_Developer_Name__c LIMIT 1];
            if (!documents.isEmpty()) {
                generateNewDocumentVersion(quote, documents.get(0).Id, DIRECT_DEBIT_DOCUMENT_NAME, 2);
            }
        }
    }
}