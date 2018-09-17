public with sharing class VirtualLicAgreementGenerator extends QuoteDocumentParams {

    public static final String HEADLINE_PRODUCTS_CODES = 'BVLF,BVLM';

    public SBQQ__Quote__c quoteDetail {get; private set;}
    public List<SBQQ__QuoteLine__c> qliList {get; set;}
    public Map<String,List<SBQQ__QuoteLine__c>> qliTypeMap {get; set;}
    public String keyString {get; set;}
    public String quoteId {get; set;}
//    public Boolean isHeadlineProductAdded { get; set; }
    public SBQQ__QuoteLine__c headlineProductLine {get; set;}

    public VirtualLicAgreementGenerator() {
        quoteId = ApexPages.currentPage().getParameters().get('id');
    }

    public PageReference init() {
        quoteDetail = DocumentGenerationHelper.getQuoteDetails(quoteId);

        qliList = DocumentGenerationHelper.getQuoteLines(quoteId);

        qliTypeMap = getQuoteLineByType(qliList);

//        System.debug('keymap--->' + keyString);
//
//        for (String key: qliTypeMap.keySet()){
//            System.debug(key+ ' -> '+ qliTypeMap.get(key));
//        }

        return null;
    }

    private Map<String, List<SBQQ__QuoteLine__c>> getQuoteLineByType(List<SBQQ__QuoteLine__c> quoteLines){
        Map<String, List<SBQQ__QuoteLine__c>> qliByType = new Map<String, List<SBQQ__QuoteLine__c>>();
        keyString = ' ';
        for (SBQQ__QuoteLine__c qLI: quoteLines) {
            if(qliByType.containsKey(qLI.SBQQ__ProductCode__c)){
                List<SBQQ__QuoteLine__c> qList = qliByType.get(qLI.SBQQ__ProductCode__c);
                qList.add(qLI);
                qliByType.put(qLI.SBQQ__ProductCode__c,qList);
            } else {
                qliByType.put(qLI.SBQQ__ProductCode__c, new List<SBQQ__QuoteLine__c> {qLI});
                keyString += qLI.SBQQ__ProductCode__c +', ';
            }

            if (HEADLINE_PRODUCTS_CODES.contains(qLI.SBQQ__ProductCode__c)) {
                headlineProductLine = qLI;
            }

        }

        return qliByType;
    }

}