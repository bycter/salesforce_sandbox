public interface QuoteDocumentGenerator {
    void updateAdditionalDocuments(SBQQ__Quote__c quote);
    void updateAdditionalDocuments(SBQQ__Quote__c quote, Map<String,String> documentParams);
}