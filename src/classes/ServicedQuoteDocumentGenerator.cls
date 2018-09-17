public class ServicedQuoteDocumentGenerator extends AbstractQuoteDocumentGenerator {

    public static final String PRICING_DOCUMENT_NAME = 'Pricing Document';
    public static final String LICENCE_AGREEMENT_DOCUMENT_NAME = 'Serviced Space Licence Agreement';
    public static final String DIRECT_DEBIT_DOCUMENT_NAME = 'Direct Debit Form';
    public static final String FAIR_USAGE_POLICY = 'Fair Usage Policy';
    public static final String CO_WORKING_DEDICATED_LICENCE_AGREEMENT_DOCUMENT_NAME = 'Co-Working Dedicated Licence Agreement';
    public static final String CO_WORKING_HOT_DESK_LICENCE_AGREEMENT_DOCUMENT_NAME = 'Co-Working Hot Desk Licence Agreement';

    public override void updateAdditionalDocuments(SBQQ__Quote__c quote, Map<String, String> documentParams) {
        List<SBQQ__QuoteLine__c> lines = [SELECT Id, SBQQ__ProductCode__c, SBQQ__Bundle__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];
        removePreviousDocumentVersion(quote, new Set<String>{
                PRICING_DOCUMENT_NAME, LICENCE_AGREEMENT_DOCUMENT_NAME, DIRECT_DEBIT_DOCUMENT_NAME, FAIR_USAGE_POLICY, CO_WORKING_DEDICATED_LICENCE_AGREEMENT_DOCUMENT_NAME, CO_WORKING_HOT_DESK_LICENCE_AGREEMENT_DOCUMENT_NAME, CAR_PARKING_DOCUMENT_NAME
        });
        if (SBQQ_QuoteService.getHeadLineSuiteItems(quote.Id).size() > 0) {
            generateNewDocumentVersion(quote, Page.ServicedPricingDocumentGenerator, PRICING_DOCUMENT_NAME, 0);
        }
        generateNewLicenceAgreementDocument(quote, lines, documentParams);
        generateNewDirectDebitDocument(quote);
        generateNewFairUsagePolicyDocument(quote);
        generateCarParkingLicenceDocument(quote, lines, documentParams, 5, true);
        generateCoWorkingDedicatedLicenceAgreement(quote, lines, documentParams);
        generateCoWorkingHotDeskLicenceAgreement(quote, lines, documentParams);
    }

    private void generateNewLicenceAgreementDocument(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> lines, Map<String, String> params) {
        if (SBQQ_QuoteService.isHeadLineProductAdded(lines, QuoteProductCodes.SERVICE_LICENCE_FEE)) {
            //For signature process, Licence Agreement Document should be required for sending
            generateNewDocumentVersion(quote, Page.ServicedSpaceLicenceAgreementPage, LICENCE_AGREEMENT_DOCUMENT_NAME, params, 1, isDocumentRequired(params));
        }
    }

    private void generateCoWorkingDedicatedLicenceAgreement(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> lines, Map<String, String> params) {
        if (SBQQ_QuoteService.isHeadLineProductAdded(lines, QuoteProductCodes.CO_WORKING_DEDICATED_LICENCE_FEE)) {
            generateNewDocumentVersion(quote, Page.CoWorkingDedicatedLicenceAgreement, CO_WORKING_DEDICATED_LICENCE_AGREEMENT_DOCUMENT_NAME, params, isDocumentRequired(params));
        }
    }

    private void generateCoWorkingHotDeskLicenceAgreement(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> lines, Map<String, String> params) {
        if (SBQQ_QuoteService.isHeadLineProductAdded(lines, QuoteProductCodes.CO_WORKING_HOT_DESK_LICENCE_FEE)) {
            generateNewDocumentVersion(quote, Page.CoWorkingHotDeskLicenceAgreement, CO_WORKING_HOT_DESK_LICENCE_AGREEMENT_DOCUMENT_NAME, params, isDocumentRequired(params));
        }
    }

    private void generateNewFairUsagePolicyDocument(SBQQ__Quote__c quote) {
        List<Document> documents = [SELECT Id FROM Document WHERE DeveloperName = 'Fair_Usage_Policy' LIMIT 1];
        if (!documents.isEmpty()) {
            generateNewDocumentVersion(quote, documents.get(0).Id, FAIR_USAGE_POLICY, 3);
        }
    }
}