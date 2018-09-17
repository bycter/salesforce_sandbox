public class ConventionalQuoteDocumentGenerator extends AbstractQuoteDocumentGenerator {

    public static final String PRICING_DOCUMENT_NAME = 'Pricing Document';
    public static final String TERMS_DOCUMENT_NAME = 'Terms Document';

    public override void updateAdditionalDocuments(SBQQ__Quote__c quote, Map<String, String> documentParams) {
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__ProductCode__c, SBQQ__Bundle__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];
        removePreviousDocumentVersion(quote, new Set<String>{
                PRICING_DOCUMENT_NAME, TERMS_DOCUMENT_NAME, CAR_PARKING_DOCUMENT_NAME
        });
        if (SBQQ_QuoteService.getHeadLineSuiteItems(quote.Id).size() > 0) {
            generateNewDocumentVersion(quote, Page.ConventionalPricingDocumentGenerator, PRICING_DOCUMENT_NAME, 0);
            generateNewTermsDocument(quote, documentParams);
        }
        generateCarParkingLicenceDocument(quote, lines, documentParams, 2, true);
    }

    private void generateNewTermsDocument(SBQQ__Quote__c quote, Map<String, String> params) {
        generateNewDocumentVersion(quote, Page.ConventionalTermDocumentGenerator, TERMS_DOCUMENT_NAME, params, 1, isDocumentRequired(params) );
    }
}