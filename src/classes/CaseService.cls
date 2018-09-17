public with sharing class CaseService {

    public static final String LEASE_TRANSACTION_RECORD_TYPE = 'Lease_Transaction';
    public static final String OUTSOURCED_LEASE_TRANSACTION_RECORD_TYPE = 'Outsourced_Lease_Transaction';
    public static final String CONVENTIONAL_ONBOARDING_RECORD_TYPE = 'Conventional_Onboarding';
    public static final String SERVICED_SPACE_ONBOARDING_RECORD_TYPE = 'Serviced_Space_Onboarding';
    public static final String DESIGN_RECORD_TYPE = 'Design';
    public static final String FIT_OUT_DESIGN_RECORD_TYPE = 'Fit_Out_Design';
    public static final String BUILDING_CONSTRUCTION_CASE_RECORD_TYPE = 'Building_Construction_Case';
    public static final String QUOTE_CASE_RECORD_TYPE = 'Quote_Case';
    public static final String CONVENTIONAL_SURRENDER_RECORD_TYPE = 'Contract_Surrender_Conventional';
    public static final String SERVICED_SURRENDER_RECORD_TYPE = 'Contract_Surrender_Serviced';

    public static final String STATUS_READY_TO_ONBOARD = 'Ready to Onboard';
    public static final String STATUS_CUSTOMER_CONFIRMED = 'Customer Confirmed';

    private static BusinessHours defaultBusinessHours;

    public static void setCaseInventory(List<Case> cases) {
        List<String> codesToFilter = new List<String>{
                ProductService.PRODUCT_CODE_OFFICE_RENT,
                ProductService.PRODUCT_CODE_LAB_SPACE,
                ProductService.PRODUCT_CODE_RETAIL_RENT
        };

        Map<Id, Case> quoteIdToCase = new Map<Id, Case>();
        for (Case theCase : cases) {
            if (theCase.Quote__c != null
                    && theCase.RecordTypeId == RecordTypeHelper.getCaseRtIdByDeveloperName(LEASE_TRANSACTION_RECORD_TYPE)) {
                quoteIdToCase.put(theCase.Quote__c, theCase);
            }
        }

        Map<Id, List<SBQQ__QuoteLine__c>> itemsMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c item : [
                SELECT Id, Inventory__c, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN:quoteIdToCase.keySet() AND Inventory__c != null
                AND SBQQ__ProductCode__c IN :codesToFilter
        ]) {

            if (!itemsMap.containsKey(item.SBQQ__Quote__c)) {
                itemsMap.put(item.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
            }
            itemsMap.get(item.SBQQ__Quote__c).add(item);
        }

        for (Case theCase : quoteIdToCase.values()) {
            if (itemsMap.containsKey(theCase.Quote__c)) {
                theCase.Inventory__c = itemsMap.get(theCase.Quote__c).get(0).Inventory__c;
            }
        }
    }

    public static void setCasePreEmptionInventory(List<Case> cases) {

        Map<Id, Case> quoteIdToCase = new Map<Id, Case>();
        for (Case theCase : cases) {
            if (theCase.Quote__c != null
                    && theCase.RecordTypeId == RecordTypeHelper.getCaseRtIdByDeveloperName(LEASE_TRANSACTION_RECORD_TYPE)) {
                quoteIdToCase.put(theCase.Quote__c, theCase);
            }
        }

        Map<Id, List<SBQQ__QuoteLine__c>> itemsMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c item : [
                SELECT Id, Inventory__c, SBQQ__Quote__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN:quoteIdToCase.keySet() AND Inventory__c != null
                AND SBQQ__ProductCode__c = :ProductService.PRODUCT_CODE_PRE_EMPTION_AGREEMENT
        ]) {

            if (!itemsMap.containsKey(item.SBQQ__Quote__c)) {
                itemsMap.put(item.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
            }
            itemsMap.get(item.SBQQ__Quote__c).add(item);
        }

        for (Case theCase : quoteIdToCase.values()) {
            if (itemsMap.containsKey(theCase.Quote__c)) {
                theCase.Pre_Emption_Inventory__c = itemsMap.get(theCase.Quote__c).get(0).Inventory__c;
            }
        }
    }

    public static BusinessHours getDefaultBusinessHours() {
        if (defaultBusinessHours == null) {
            defaultBusinessHours = [SELECT Id FROM BusinessHours WHERE IsDefault = true];
        }
        return defaultBusinessHours;
    }

    public static Case generateDefaultCase(SBQQ__Quote__c quote, Opportunity theOpportunity) {
        Case theCase = new Case();

        theCase.CurrencyIsoCode = 'GBP';
        theCase.BusinessHoursId = CaseService.getDefaultBusinessHours().Id;
        theCase.Briefing_Statement__c = theOpportunity.Briefing_Statement__c;
        theCase.AccountId = theOpportunity.AccountId;
        theCase.Opportunity__c = theOpportunity.Id;
        theCase.Property__c = quote.Property__c;
        theCase.Quote__c = quote.Id;
        return theCase;
    }

    public static Case generateDefaultOnboardingCase(SBQQ__Quote__c quote, List<SBQQ__QuoteLine__c> headlineQlis, Opportunity theOpportunity) {
        Case theCase = generateDefaultCase(quote, theOpportunity);
        theCase.Status = 'New';
        //theCase.Briefing_Statement__c = theOpportunity.Briefing_Statement__c;
        theCase.Sales_Contact__c = quote.SBQQ__PrimaryContact__c;
        for (SBQQ__QuoteLine__c headLine: headlineQlis) {
            if (headLine.Start_Date__c != null) {
                theCase.Commencement_Date__c = headLine.Start_Date__c;
            }
        }
        return theCase;
    }

    public static void setOffLineEdits(List<Case> cases) {
        Map<Id, List<Case>> casesMappedByQuoteId = SObjectUtils.getIdMapFromObjects(cases, 'Quote__c');
        List<SBQQ__Quote__c> quotes = [SELECT Id, Off_line_Edits__c FROM SBQQ__Quote__c WHERE Id = :casesMappedByQuoteId.keySet()];
        for (SBQQ__Quote__c quote : quotes) {
            for (Case c : casesMappedByQuoteId.get(quote.Id)) {
                c.Off_line_Edits__c = quote.Off_line_Edits__c;
            }
        }
    }

    public static Case generateDefaultLeaseTransactionCase(SBQQ__Quote__c quote, Opportunity theOpportunity) {
        Case theCase = generateDefaultCase(quote, theOpportunity);

        theCase.Status = 'Instructed';
        theCase.Legacy_contract__c = quote.Legacy_contract__c;
        theCase.Contract__c = quote.Contract__c;
        theCase.Sales_Contact__c = quote.SBQQ__PrimaryContact__c;
        return theCase;
    }
}