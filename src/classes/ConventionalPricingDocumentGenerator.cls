public class ConventionalPricingDocumentGenerator {

    public SBQQ__Quote__c quote { get; set; }

    public List<SBQQ__QuoteLine__c> lineItems { get; set; }

    public Map<SBQQ__QuoteLine__c, List<SBQQ__QuoteLine__c>> bundles { get; set; }
    public Map<SBQQ__QuoteLine__c, Map<Integer, Decimal>> rentsByYears { get; set; }
    public Map<SBQQ__QuoteLine__c, String> breakOptions { get; set; }
    public Map<SBQQ__QuoteLine__c, Integer> rentYearsCount { get; set; }
    public Map<SBQQ__QuoteLine__c, String> rentYearsAndMonth { get; set; }

    public String actualPortfolio { get; set; }
    public Integer countOfBundels { get; set; }

    public ConventionalPricingDocumentGenerator() {
        rentYearsAndMonth = new Map<SBQQ__QuoteLine__c, String>();
        rentYearsCount = new Map<SBQQ__QuoteLine__c, Integer>();
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('id');
        quote = DocumentGenerationHelper.getQuoteDetails(quoteId);
        actualPortfolio = obtainActualPortfolio(quote);
        bundles = new Map<SBQQ__QuoteLine__c, List<SBQQ__QuoteLine__c>>();
        rentsByYears = new Map<SBQQ__QuoteLine__c, Map<Integer, Decimal>>();
        breakOptions = new Map<SBQQ__QuoteLine__c, String>();
        lineItems = DocumentGenerationHelper.getQuoteLines(quoteId);
        for (SBQQ__QuoteLine__c lineItem : lineItems) {
            if (DocumentGenerationHelper.isSuiteBundle(lineItem)) {
                bundles.put(lineItem, getBundleItems(lineItem));
                breakOptions.put(lineItem, getBreakOptionsString(lineItem));
                if (lineItem.Term__c != null) {

                    rentYearsAndMonth.put(lineItem, NumberUtils.convertMonthsToYears(Integer.valueOf(lineItem.Term__c)));
                    rentYearsCount.put(lineItem, Math.ceil(Integer.valueOf(lineItem.Term__c) / 12.0).intValue());
                    rentsByYears.put(lineItem, getRentsByYears(lineItem, Integer.valueOf(lineItem.Term__c)));
                }
            }
        }

        countOfBundels = bundles.size();
    }

    private String obtainActualPortfolio(SBQQ__Quote__c quote) {
        return String.isBlank(quote.Property__r.Portfolio__c) ? SBQQ_QuoteConstants.DEFAUL_PORTFOLIO_NAME : quote.Property__r.Portfolio__c;
    }

    private List<SBQQ__QuoteLine__c> getBundleItems(SBQQ__QuoteLine__c bundle) {
        List<SBQQ__QuoteLine__c> bundleItems = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c lineItem : lineItems) {
            if (lineItem.SBQQ__RequiredBy__c == bundle.Id) {
                bundleItems.add(lineItem);
            }
        }
        return bundleItems;
    }

    private List<Integer> getBundleTerms(Decimal months) {
        Integer years = Math.ceil(months / 12.0).intValue();
        List<Integer> terms = new List<Integer>();
        for (Integer i = 1; i <= years; i++) {
            terms.add(i);
        }
        return terms;
    }

    private String getBreakOptionsString(SBQQ__QuoteLine__c bundle) {
        String breakOptionsString = '';
        List<Integer> yearsWhenBreakOptionApplied = getMonthWhenBreakOptionApplied(bundle);
        //The list should be sorted to display values in ascending order (For example: 1st, 2nd, 4th years)
        yearsWhenBreakOptionApplied.sort();
        for (Integer yearWhenBreakoptionApplied : yearsWhenBreakOptionApplied) {
            breakOptionsString += yearWhenBreakoptionApplied + NumberUtils.getOrdinalNumber(yearWhenBreakoptionApplied) + ', ';
        }
        if (!String.isBlank(breakOptionsString)) {
            //Removes extra comma
            breakOptionsString = breakOptionsString.removeEnd(', ');
            //If the string contains comma, it means there are several values in the string
            breakOptionsString += breakOptionsString.contains(',') ? ' months' : ' month';
        }
        return breakOptionsString;
    }

    private List<Integer> getMonthWhenBreakOptionApplied(SBQQ__QuoteLine__c bundle) {
        //Stores the list of years in which Break Option will be applied for specific bundle
        List<Integer> monthWhenBreakOptionApplied = new List<Integer>();
        for (SBQQ__QuoteLine__c lineItem : lineItems) {
            if (lineItem.SBQQ__RequiredBy__c == bundle.Id && lineItem.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_CUSTOMER_BREAK
                    && lineItem.Break_Date__c != null) {
                Integer breakDate = Math.ceil(lineItem.Break_Date__c).intValue();
                monthWhenBreakOptionApplied.add(breakDate);
            }
        }
        return monthWhenBreakOptionApplied;
    }

    private Set<SBQQ__QuoteLine__c> getConcessionLineItems(List<SBQQ__QuoteLine__c> lineItems) {
        Set<SBQQ__QuoteLine__c> concessionLineItems = new Set<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c lineItem : lineItems) {
            String productCode = lineItem.SBQQ__ProductCode__c;
            if (productCode == ProductService.PRODUCT_CODE_FREE_RENT
                    || productCode == ProductService.PRODUCT_CODE_HALF_RENT
                    || productCode == ProductService.PRODUCT_CODE_STEPPED_RENT) {
                concessionLineItems.add(lineItem);
            }
        }
        return concessionLineItems;
    }

    private Map<Integer, Decimal> getRentsByYears(SBQQ__QuoteLine__c bundle, Integer months) {
        Map<Integer, Double> rentsByYears = new Map<Integer, Double>();
        Set<SBQQ__QuoteLine__c> concessionLineItems = getConcessionLineItems(getBundleItems(bundle));
        for (Integer month = 1; month <= months; month++) {
            Integer year = Math.ceil(month / 12.0).intValue();
            if (!rentsByYears.containsKey(year)) {
                rentsByYears.put(year, bundle.Monthly_Average__c);
            } else {
                rentsByYears.put(year, rentsByYears.get(year) + bundle.Monthly_Average__c);
            }
            for (SBQQ__QuoteLine__c concessionLineItem : concessionLineItems) {
                rentsByYears.put(year, rentsByYears.get(year) - calculateConcessionForMonth(month, concessionLineItem));
            }
        }
        return rentsByYears;
    }

    private Double calculateConcessionForMonth(Integer month, SBQQ__QuoteLine__c concessionLineItem) {
        Double concessionForYear = 0;
        if (month > concessionLineItem.Start_Term__c && month <= concessionLineItem.Start_Term__c + concessionLineItem.Term__c) {
            concessionForYear = concessionLineItem.Discount_Total__c / concessionLineItem.Term__c;
        }
        return concessionForYear;
    }
}