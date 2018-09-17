public with sharing class ServicedPricingDocumentGenerator extends QuoteDocumentParams{
    public SBQQ__Quote__c quoteDetail {get; private set;}
    public List<SBQQ__QuoteLine__c> qliList {get;set;}
    public Map<String,List<SBQQ__QuoteLine__c>> qliTypeMap {get;set;}
    public Map<String, List<SBQQ__QuoteLine__c>> bundleSteppedRentMap { get; set; }
    public String keyString {get;set;}
    public String quoteId {get;set;}
    public Boolean isSuiteProductAdded { get; set; }
    public List<ProductRow> additionalProducts {set;}
    public String suiteType {get;set;}
    public Integer numberOfWorkstations { get; set; }

    public class ProductRow {
        public String ProductName {get;set;}
        public String ProductDescription {get;set;}

        public ProductRow(String ProductName, String ProductDescription) {
            this.ProductName = ProductName;
            this.ProductDescription = ProductDescription;
        }

    }
    public ServicedPricingDocumentGenerator() {
        quoteId = ApexPages.currentPage().getParameters().get('id');
    }

    public PageReference init() {
        quoteDetail = DocumentGenerationHelper.getQuoteDetails(quoteId);
        qliList = DocumentGenerationHelper.getQuoteLines(quoteId);
        qliTypeMap = DocumentGenerationHelper.obtainMapProducts(qliList);
        keyString = DocumentGenerationHelper.obtainCodes(qliTypeMap);
        suiteType = DocumentGenerationHelper.getSuiteType(qliList);
        isSuiteProductAdded = suiteType != null;
        bundleSteppedRentMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_STEPPED_RENT, qliList);
        if (bundleSteppedRentMap.size() > 0) {
            qliTypeMap.put(ProductService.PRODUCT_CODE_STEPPED_RENT,
                    DocumentGenerationHelper.addFullPriceSteps(bundleSteppedRentMap.get(qliTypeMap.get(suiteType)[0].Id),
                            qliTypeMap.get(suiteType)[0]));
        }
//        for (SBQQ__QuoteLine__c allSteps : DocumentGenerationHelper.addFullPriceSteps(bundleSteppedRentMap.get(qliTypeMap.get(suiteType)[0].Id),
//                qliTypeMap.get(suiteType)[0])) {
//            System.debug('--->' + allSteps);
//        }
        numberOfWorkstations = calculateNumberOfWorkstations(qliList);

//        System.debug('keymap--->' + keyString + ' ++'+ suiteType);
//
//        for (String key: qliTypeMap.keySet()){
//            System.debug(key+ ' -> '+ qliTypeMap.get(key));
//        }

        return null;
    }

    public List<ProductRow>  getAdditionalProducts() {
        List<ProductRow> additionalProducts = new List<ProductRow>();
        for (String key: qliTypeMap.keySet()) {

            if (key == ProductService.PRODUCT_CODE_CAR_PARKING_LEASE) {
                additionalProducts.add(new ProductRow(qliTypeMap.get(key).get(0).SBQQ__Quantity__c.setScale(0) + ' car parking space(s):',
                        NumberUtils.convertToCurrency(qliTypeMap.get(key).get(0).Monthly_Cost__c) + ' per space pcm + VAT'));
            }


            if (key.contains('BSDM')) {
                additionalProducts.add(new ProductRow(qliTypeMap.get(key).get(0).SBQQ__Product__r.Name + ':',
                            NumberUtils.convertToCurrency(qliTypeMap.get(key).get(0).Monthly_Average_Without_Discount__c)  + ' pcm + VAT'));
                }

            if (key == 'BSII') {
                additionalProducts.add(new ProductRow(qliTypeMap.get(key).get(0).SBQQ__Product__r.Name + ':',
                        NumberUtils.convertToCurrency(qliTypeMap.get(key).get(0).Monthly_Average_Without_Discount__c) + ' per person pcm + VAT'));
            }

        }

        return additionalProducts;
    }

    private Integer calculateNumberOfWorkstations(List<SBQQ__QuoteLine__c> quoteLines) {
        Integer numberOfWorkstations = 0;
        Set<String> productCodesWithQuantity = new Set<String>{QuoteProductCodes.SERVICE_LICENCE_FEE, QuoteProductCodes.ADDITIONAL_DESKS, QuoteProductCodes.CO_WORKING_HOT_DESK_LICENCE_FEE};
        for ( SBQQ__QuoteLine__c quoteLine : quoteLines ) {
            if ( quoteLine.SBQQ__ProductCode__c == QuoteProductCodes.DEDICATED_DESK_SPACE ) {
                numberOfWorkstations += 1;
            } else if ( productCodesWithQuantity.contains(quoteLine.SBQQ__ProductCode__c) ) {
                numberOfWorkstations += Integer.valueOf(quoteLine.SBQQ__Quantity__c);
            }
        }
        return numberOfWorkstations;
    }


}