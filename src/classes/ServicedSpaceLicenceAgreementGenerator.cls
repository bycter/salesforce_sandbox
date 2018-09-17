public class ServicedSpaceLicenceAgreementGenerator extends QuoteDocumentParams {

    public SBQQ__Quote__c quote { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> mapProducts { get; set; }
    public String codes { get; set; }
    public Boolean isSuiteProductAdded { get; set; }
    public String callHandlingScheduleNames {get; set;}
    public Map<String, List<SBQQ__QuoteLine__c>> bundleSteppedRentMap { get; set; }
    public List<SBQQ__QuoteLine__c> carParkingLicences { get; set; }

    public ServicedSpaceLicenceAgreementGenerator() {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('id');
        quote = DocumentGenerationHelper.getQuoteDetails(quoteId);
        List<SBQQ__QuoteLine__c> lineItems = DocumentGenerationHelper.getQuoteLines(quoteId);
        mapProducts = DocumentGenerationHelper.obtainMapProducts(lineItems);
        codes = DocumentGenerationHelper.obtainCodes(mapProducts);
        //carParkingLicences = obtainCarParkingLicences(lineItems);
        carParkingLicences = DocumentGenerationHelper.getBundleProductMap(ProductService.CAR_PARKING_LICENCE_CODE,
                lineItems).get(mapProducts.get(ProductService.PRODUCT_CODE_SERVICED)[0].Id);
        bundleSteppedRentMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_STEPPED_RENT, lineItems);
        if (bundleSteppedRentMap.size() > 0) {
            mapProducts.put(ProductService.PRODUCT_CODE_STEPPED_RENT,
                    DocumentGenerationHelper.addFullPriceSteps(bundleSteppedRentMap.get(mapProducts.get(ProductService.PRODUCT_CODE_SERVICED)[0].Id),
                            mapProducts.get(ProductService.PRODUCT_CODE_SERVICED)[0]));
        }

        isSuiteProductAdded = DocumentGenerationHelper.getSuiteType(lineItems) != null;
        setCallHandlingScheduleNames();
    }

    public void setCallHandlingScheduleNames(){
        callHandlingScheduleNames = ' ';
        if (codes.contains(ProductService.CALL_HANDLING_CODE)){
            for (SBQQ__QuoteLine__c line : mapProducts.get(ProductService.CALL_HANDLING_CODE))
            {
                callHandlingScheduleNames += line.SBQQ__ProductOption__r.SBQQ__Feature__r.name;
            }
        }
    }

}