public class CoWorkingLicenceAgreement extends QuoteProductCodes {
    public SBQQ__Quote__c quote { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundleSteppedRentMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> mapProducts { get; set; }
    public String codes { get; set; }

    public CoWorkingLicenceAgreement() {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('id');
        quote = DocumentGenerationHelper.getQuoteDetails(quoteId);
        List<SBQQ__QuoteLine__c> lineItems = DocumentGenerationHelper.getQuoteLines(quoteId);
        mapProducts = DocumentGenerationHelper.obtainMapProducts(lineItems);
        codes = DocumentGenerationHelper.obtainCodes(mapProducts);
        String suiteType = DocumentGenerationHelper.getSuiteType(lineItems);
        bundleSteppedRentMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_STEPPED_RENT, lineItems);
        if (bundleSteppedRentMap.size() > 0) {
            mapProducts.put(ProductService.PRODUCT_CODE_STEPPED_RENT,
                    DocumentGenerationHelper.addFullPriceSteps(bundleSteppedRentMap.get(mapProducts.get(suiteType)[0].Id),
                            mapProducts.get(suiteType)[0]));
        }
    }
}