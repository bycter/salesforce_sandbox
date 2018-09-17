public class ConventionalTermDocumentGenerator extends QuoteDocumentParams {
    public SBQQ__Quote__c quoteDetail { get; private set; }
    public SBQQ__QuoteLine__c qLI { get; set; }
    public List<SBQQ__QuoteLine__c> qliList { get; set; }
    public List<Map<String, SBQQ__QuoteLine__c>> bundleProducts { get; set; }
    public Map<String, BreakOptions> bundleBreakOptions { get; set; }
    public Map<String, BreakOptions> bundleSupplierBreakOptions { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundleRentReviewMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundlePreEmptionMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundleFreeRentMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundleHalfRentMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundleRentMap { get; set; }
    public Map<String, List<SBQQ__QuoteLine__c>> bundleSteppedRentMap { get; set; }
    public Map<String, String> keyList { get; set; }
    public Map<String, String> suiteTypesMap { get; set; }
    public String accountFullAddress { set; }
    public Boolean fitOutAdded { get; set; }
    public Boolean suiteAdded { get; set; }
    public Integer numCarParkingLeases { get; set; }
    public Integer numCarParkingLicenses { get; set; }
    public Map<String, Decimal> businessRatesPerSqFtMap { get; set; }
    public String legacyContractsInventories { get; set; }
    public String legacyContractProperty { get; set; }
    public String legacyContractDateX { get; set; }
    public String legacyContractWeeksX { get; set; }
    public String surrenderDeedCompletionDate { get; set; }
    public Double VAT { get; set; }

    protected String quoteId;

    public Boolean surrenderWasRendered;

    private class BreakOptions {
        public String breakDates { get; set; }
        public String noticedDates { get; set; }
        public String breakPenalty { get; set; }
        public Boolean breakPenaltyExists { get; set; }

        public BreakOptions() {
            breakDates = '';
            noticedDates = '';
            breakPenalty = '';
            breakPenaltyExists = false;
        }
    }


    public ConventionalTermDocumentGenerator() {
        quoteId = ApexPages.currentPage().getParameters().get('id');
        keyList = new Map<String, String>();
        fitOutAdded = false;
        suiteAdded = false;
        businessRatesPerSqFtMap = new Map<String, Decimal>();
        suiteTypesMap = new Map<String, String>();
        VAT = Constants.VAT_TAX;
    }

    public PageReference init() {

        quoteDetail = DocumentGenerationHelper.getQuoteDetails(quoteId);
        qliList = DocumentGenerationHelper.getQuoteLines(quoteId);
        bundleProducts = getBundleProducts(qliList);
        bundleBreakOptions = getMapBreakOptions(QuoteProductCodes.CUSTOMER_BREAK_OPTION);
        bundleSupplierBreakOptions = getMapBreakOptions(QuoteProductCodes.SUPPLIER_BREAK_OPTION);
        numCarParkingLeases = getNumCarParking(ProductService.PRODUCT_CODE_CAR_PARKING_LEASE);
        numCarParkingLicenses = getNumCarParking(ProductService.PRODUCT_CODE_CAR_PARKING_LICENSE);
        bundleRentReviewMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_RENT_REVIEW, qliList);
        bundlePreEmptionMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_PRE_EMPTION_AGREEMENT, qliList);
        bundleFreeRentMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_FREE_RENT, qliList);
        bundleHalfRentMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_HALF_RENT, qliList);
        bundleSteppedRentMap = DocumentGenerationHelper.getBundleProductMap(ProductService.PRODUCT_CODE_STEPPED_RENT, qliList);
        bundleRentMap = getSortedByTermRents(bundleFreeRentMap,bundleHalfRentMap);
        legacyContractsInventories = getLContractsInventories();
        surrenderDeedCompletionDate = generateSurrenderDeedCompletionDate();


        return null;
    }

    private String getLContractsInventories() {
        List<ContractToQuote__c> contractsToQuote = [select Contract__c from ContractToQuote__c where Quote__c = :quoteDetail.Id];
        Set<Id> contractIds = new Set<Id>();
        for (ContractToQuote__c contractToQuote : contractsToQuote) {
            contractIds.add(contractToQuote.Contract__c);
        }
        List<SBQQ__Subscription__c> subscriptions = [
                select Id, Inventory__r.Name, Inventory__r.Property__r.Name
                from SBQQ__Subscription__c
                where SBQQ__Contract__c in:contractIds
                and SBQQ__QuoteLine__r.SBQQ__Bundle__c = true and SBQQ__QuoteLine__r.SBQQ__ProductFamily__c = : ProductService.PRODUCT_FAMILY_SUITE
        ];

        Map<String, List<String>> propertyInventoryMap = new Map<String, List<String>>();
        for (SBQQ__Subscription__c subscription : subscriptions) {
            if (subscription.Inventory__c != null && String.isNotBlank(subscription.Inventory__r.Name)) {
                if (propertyInventoryMap.get(subscription.Inventory__r.Property__r.Name) == null) {
                    propertyInventoryMap.put(subscription.Inventory__r.Property__r.Name, new List<String>());
                }
                propertyInventoryMap.get(subscription.Inventory__r.Property__r.Name).add(subscription.Inventory__r.Name);
            }
        }

        List<String> propertyWithInventories = new List<String>();
        for (String propertyName : propertyInventoryMap.keySet()) {
            propertyWithInventories.add(String.join(propertyInventoryMap.get(propertyName), ', ') + ' - ' + propertyName);
        }
        return String.join(propertyWithInventories, '; ');
    }

    public Boolean getQuoteWithoutSuites() {
        return !haveIntersection(suiteTypesMap.values(), QuoteFromContractCreator.HEADLINE_PRODUCT_CODES);
    }

    public Boolean getSurrenderWasRendered() {
        if (surrenderWasRendered == null) {
            surrenderWasRendered = true;
            return false;
        } else {

            return surrenderWasRendered;
        }
    }

    private Boolean haveIntersection(List<String> firstList, List<String> secondList) {
        for (String testString : firstList) {
            if (secondList.contains(testString)) {
                return true;
            }
        }
        return false;
    }

    private List<Map<String, SBQQ__QuoteLine__c>> getBundleProducts(List<SBQQ__QuoteLine__c> quoteLines) {
        List<Map<String, SBQQ__QuoteLine__c>> qliByBundles = new List<Map<String, SBQQ__QuoteLine__c>>();

        for (SBQQ__QuoteLine__c qliHead : quoteLines) {
            if (DocumentGenerationHelper.isSuiteBundle(qliHead)) {
                Map<String, SBQQ__QuoteLine__c> qliByCode = new Map<String, SBQQ__QuoteLine__c>();
                String ks = '';
                Decimal businesRates = 0;
                for (SBQQ__QuoteLine__c qLI : quoteLines) {
                    if (qli.SBQQ__RequiredBy__c == qliHead.Id && !String.isBlank(qli.SBQQ__RequiredBy__c)
                            || (qliHead.SBQQ__ProductCode__c != ProductService.PRODUCT_CODE_STORAGE
                            && qli.SBQQ__ProductFamily__c == ProductService.PRODUCT_FAMILY_PARKING)) {
                        if (!qliByCode.containsKey(qLI.SBQQ__ProductCode__c)) {
                            kS += ' ' + qLI.SBQQ__ProductCode__c + ',';
                        }

                        if (qli.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_FIT_OUT_SUPPLIER) {
                            fitOutAdded = true;
                        }

                        qliByCode.put(qLI.SBQQ__ProductCode__c, qLI);

                    }
                }
                qliByCode.put('Suite', qliHead);
                ks += ' Suite,';
                suiteAdded = true;
                keyList.put(qliHead.Id, ks);
                suiteTypesMap.put(qliHead.Id, qliHead.SBQQ__ProductCode__c);
                qliByBundles.add(qliByCode);
                if (qliHead.Square_Footage__c != NULL
                        && qliHead.Square_Footage__c != 0
                        && quoteDetail.Estimated_Business_Rate_Per_Annum__c != NULL
                        ) {
                    businesRates = (quoteDetail.Estimated_Business_Rate_Per_Annum__c / qliHead.Square_Footage__c).setScale(2);
                }
                //businesRates = qliHead.Rent_per_Sq_Ft_annual__c.setScale(2);
                //System.debug(businesRates + ' ' + qliHead.id);
                businessRatesPerSqFtMap.put(qliHead.id, businesRates);

            }
        }

        return qliByBundles;
    }

    public String getAccountFullAddress() {

        String address;
        address = String.isNotBlank(quoteDetail.SBQQ__Account__r.ShippingStreet) ? quoteDetail.SBQQ__Account__r.ShippingStreet + ' ' : '';
        address += String.isNotBlank(quoteDetail.SBQQ__Account__r.ShippingCity) ? quoteDetail.SBQQ__Account__r.ShippingCity + ' ' : '';
        address += String.isNotBlank(quoteDetail.SBQQ__Account__r.ShippingPostalCode) ? quoteDetail.SBQQ__Account__r.ShippingPostalCode + ' ' : '';
        address += String.isNotBlank(quoteDetail.SBQQ__Account__r.ShippingCountry) ? quoteDetail.SBQQ__Account__r.ShippingCountry : '';
        return address;

    }

    public Integer getNumCarParking(String code) {
        Integer numCP = 0;
        for (SBQQ__QuoteLine__c qli : qliList) {
            numCP += qli.SBQQ__ProductCode__c == code ? 1 : 0;
        }

        return numCP;
    }

    public Map<String, BreakOptions> getMapBreakOptions(String productCode) {

        Map<String, BreakOptions> mapBreakOptions = new Map<String, BreakOptions>();

        for (SBQQ__QuoteLine__c qlHead : qliList) {
            //search for Headline
            if (DocumentGenerationHelper.isSuiteBundle(qlHead)) {
                BreakOptions breakOpt = new BreakOptions();
                for (SBQQ__QuoteLine__c ql : qliList) {
                    //search related Break products and build formatted strings
                    if (ql.SBQQ__ProductCode__c == productCode &&
                            ql.SBQQ__RequiredBy__c == qlHead.Id) {

                        if (breakOpt.BreakDates.length() == 0) {

                            breakOpt.breakDates = String.valueOf(ql.Break_Date__c.setScale(0));
                            if (ql.Minimum_Notice__c != NULL && ql.Maximum_Notice__c != NULL) {
                                breakOpt.noticedDates = ql.Minimum_Notice__c.setScale(0) + ' and ' + ql.Maximum_Notice__c.setScale(0);
                            }
                            breakOpt.breakPenalty = ql.Break_Penalty__c == null ? '' : String.valueOf(ql.Break_Penalty__c.format());
                            if (ql.Break_Penalty__c > 0) {
                                breakOpt.breakPenaltyExists = true;
                            }

                        } else {

                            breakOpt.breakDates += ', ' + ql.Break_Date__c.setScale(0);

                        }
                    }

                }

                mapBreakOptions.put(qlHead.Id, breakOpt);
            }
        }

        return mapBreakOptions;
    }

    private Map<String, List<SBQQ__QuoteLine__c>> getSortedByTermRents(Map<String, List<SBQQ__QuoteLine__c>> bundleFreeRent,
            Map<String, List<SBQQ__QuoteLine__c>> bundleHalfRent) {
        Map<String, List<SBQQ__QuoteLine__c>> sortedMergedBundle = new Map<String, List<SBQQ__QuoteLine__c>>();

        for (String key: bundleFreeRent.keySet()) {

            if (bundleHalfRent.containsKey(key)) {
                List<SBQQ__QuoteLine__c> qLineListToSort = new List<SBQQ__QuoteLine__c>();
                qLineListToSort.addAll(bundleFreeRent.get(key));
                qLineListToSort.addAll(bundleHalfRent.get(key));
                SortSobs.ascending(qLineListToSort, DocumentGenerationHelper.START_CONCESSION_TERM_FIELD);
                sortedMergedBundle.put(key, qLineListToSort);
            } else {
                SortSobs.ascending(bundleFreeRent.get(key), DocumentGenerationHelper.START_CONCESSION_TERM_FIELD);
                sortedMergedBundle.put(key, bundleFreeRent.get(key));
            }
        }

        for (String key: bundleHalfRent.keySet()) {
            if (!sortedMergedBundle.containsKey(key)) {
                SortSobs.ascending(bundleHalfRent.get(key), DocumentGenerationHelper.START_CONCESSION_TERM_FIELD);
                sortedMergedBundle.put(key, bundleHalfRent.get(key));
            }
        }

        return sortedMergedBundle;
    }

    public String generateSurrenderDeedCompletionDate() {
        if (quoteDetail.Surrender_deed_due_date__c != null) {
            return 'The surrender deed will complete on ' + quoteDetail.Surrender_deed_due_date__c.format() + ' date.';
        } else if (quoteDetail.Surrender_deed_weeks__c != null) {
            return 'The surrender deed will complete ' + quoteDetail.Surrender_deed_weeks__c + ' weeks after completion of the lease.';
        } else {
            return 'The surrender deed will complete on the same date as the lease.';
        }
    }

}