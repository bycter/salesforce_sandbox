public with sharing class SBQQ_QuoteService {
    /**
     * static variables to share in Trigger
     */
    private static Map<Id, Property__c> propertiesFromQuotes = new Map<Id, Property__c>();
    private static Map<Id, Opportunity> opportunitiesFromQuotes = new Map<Id, Opportunity>();
    private static Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteIds = new Map<Id, List<SBQQ__QuoteLine__c>>();

    private static Map<Id, RecordType> quoteRecordTypes;
    public static Map<Id, RecordType> getRecrodTypes() {
        if (quoteRecordTypes == null) {
            quoteRecordTypes = new Map<Id, RecordType>(
                    RecordTypeHelper.getRecordTypesForSObject(RecordTypeHelper.SBQQ_QUOTE_SOBJECT)
            );
        }
        return quoteRecordTypes;
    }

    public static Set<Id> getConventionalRecordTypeIds() {
        return getRecordTypeIdsByName(SBQQ_QuoteConstants.CONVENTIONAL_RECORD_TYPE);
    }

    public static Set<Id> getServicedRecordTypeIds() {
        return getRecordTypeIdsByName(SBQQ_QuoteConstants.SERVICED_RECORD_TYPE);
    }

    public static Set<Id> getVirtualRecordTypeIds() {
        return getRecordTypeIdsByName(SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE);
    }

    public static RecordType getRecordTypeByDeveloperName(String name) {
        for (RecordType recordType : getRecrodTypes().values()) {
            if (recordType.DeveloperName == name) {
                return recordType;
            }
        }
        return null;
    }

    public static void setCallExpiryFullTermField(List<SBQQ__Quote__c> quotes) {
        List<String> serviceProductCodes = new List<String>{
                ProductService.PRODUCT_CODE_SERVICE_CHARGE,
                ProductService.PRODUCT_CODE_SERVICE_CHARGE_CAP
        };

        Map<Id, SBQQ__Quote__c> quotesToModify = new Map<Id, SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : quotes) {
            if (quote.SBQQ__Status__c.equals(SBQQ_QuoteConstants.STATUS_ACCEPTED)) {
                quotesToModify.put(quote.Id, quote);
            }
        }

        Map<Id, List<SBQQ__QuoteLine__c>> bundlesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c item : [
                SELECT Id,
                        // fields to process
                        Cap_Expiry_Month__c, Term__c, SBQQ__RequiredBy__c,
                        SBQQ__ProductCode__c, SBQQ__Quote__c,
                        // select headline for service charge
                        SBQQ__RequiredBy__r.Cap_Expiry_Month__c, SBQQ__RequiredBy__r.Term__c,
                        SBQQ__RequiredBy__r.SBQQ__Quote__c, SBQQ__RequiredBy__r.SBQQ__ProductCode__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN:quotesToModify.keySet()
                AND SBQQ__ProductCode__c IN :serviceProductCodes
                AND SBQQ__RequiredBy__c != null
        ]) {

            if (!bundlesMap.containsKey(item.SBQQ__RequiredBy__c)) {
                bundlesMap.put(item.SBQQ__RequiredBy__c, new List<SBQQ__QuoteLine__c>());
            }
            bundlesMap.get(item.SBQQ__RequiredBy__c).add(item);
        }

        for (List<SBQQ__QuoteLine__c> lineItems : bundlesMap.values()) {
            // if 2 bundle items (Service Charge + Service Charge Cap)
            if (lineItems.size() != 2) {
                continue;
            }

            for (SBQQ__QuoteLine__c item : lineItems) {
                if (item.SBQQ__ProductCode__c.startsWith(ProductService.PRODUCT_CODE_SERVICE_CHARGE_CAP)) {

                    SBQQ__Quote__c tmpQuote = quotesToModify.get(item.SBQQ__Quote__c);
                    if (!tmpQuote.CapExpiryFullTerm__c) {
                        tmpQuote.CapExpiryFullTerm__c = item.Cap_Expiry_Month__c >= item.SBQQ__RequiredBy__r.Term__c;
                    }
                    break;
                }
            }
        }
    }

    public static void setCarParkingInfo(List<SBQQ__Quote__c> quotes) {
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesMap = SBQQ_QuoteService.getQuoteLinesMap(quotes);
        Id carParkingInventoryRT = RecordTypeHelper.getRtIdByDeveloperName('Inventory__c', 'Car_Parking');

        for (SBQQ__Quote__c quote : quotes) {
            if (quoteLinesMap.containsKey(quote.Id)) {
                // calculate the total parking spaces
                Integer totalParkingSpaces = 0;
                Decimal totalAnnualisedCost = 0;

                Map<Id, SBQQ__QuoteLine__c> tmpMapOfCarParkingLicense = new Map<Id, SBQQ__QuoteLine__c>();
                Map<Id, SBQQ__QuoteLine__c> quoteLines = new Map<Id, SBQQ__QuoteLine__c>(quoteLinesMap.get(quote.Id));

                for (SBQQ__QuoteLine__c qLine : quoteLines.values()) {
                    if (qLine.Inventory__r.RecordTypeId == carParkingInventoryRT) {
                        //Total = 'Car_Parking'
                        totalParkingSpaces++;
                        //  Annualised Cost calculation for CarParkingLease
                        totalAnnualisedCost += qLine.Net_Total__c != null && qLine.Term__c != null && qLine.Term__c > 0
                                ? ((qLine.Net_Total__c / qLine.Term__c) * 12)
                                : 0;
                    }

                    if (qLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_CAR_SPACE &&
                            qLine.SBQQ__RequiredBy__c != null && quoteLines.containsKey(qLine.SBQQ__RequiredBy__c)) {
                        SBQQ__QuoteLine__c carParkLicenseQLI = quoteLines.get(qLine.SBQQ__RequiredBy__c);
                        tmpMapOfCarParkingLicense.put(carParkLicenseQLI.Id, carParkLicenseQLI);
                    }
                }

                // Annualised Cost calculation for CarParkingLicense
                for (SBQQ__QuoteLine__c qLine : tmpMapOfCarParkingLicense.values()) {
                    totalAnnualisedCost += qLine.Net_Total__c != null && qLine.Term__c != null && qLine.Term__c > 0
                            ? ((qLine.Net_Total__c / qLine.Term__c) * 12)
                            : 0;
                }
                quote.Total_Parking_Spaces__c = totalParkingSpaces;
                quote.Total_Annualised_Cost_of_Parking_Spaces__c = totalAnnualisedCost;
            }
        }
    }

    public static void setDealSizeAndNetFillInfo(List<SBQQ__Quote__c> quotes) {
        setTotalDealSizeInfo(quotes);
        setNetFillInfo(quotes);
    }

    private static void setTotalDealSizeInfo(List<SBQQ__Quote__c> quotes) {
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesMap = getQuoteLinesMap(quotes);
        for (SBQQ__Quote__c quote : quotes) {
            quote.Total_deal_size_Sq_ft__c = 0;
            quote.Total_deal_size_Workstations__c = 0;
            if (quoteLinesMap.containsKey(quote.Id)) {
                for (SBQQ__QuoteLine__c line : quoteLinesMap.get(quote.Id)) {
                    if (isHeadLineProduct(line) && isLineRelatedToSpecifiedInventoryRecordTypes(line, new Set<String>{
                            'Actual_Suite', 'Proposed_Suite'
                    })) {
                        quote.Total_deal_size_Sq_ft__c += NumberUtils.convertNullToZero(line.Suite_Inventory__r.Size_sq_ft__c);
                        quote.Total_deal_size_Workstations__c += NumberUtils.convertNullToZero(line.Suite_Inventory__r.Workstations__c);
                    }
                }
            }
        }
    }

    private static void setNetFillInfo(List<SBQQ__Quote__c> quotes) {
        Map<Id, SBQQ__Quote__c> quotesMappedById = new Map<Id, SBQQ__Quote__c>(quotes);
        Map<Id, List<ContractToQuote__c>> contractToQuoteMappedByQuoteId = SObjectUtils.getIdMapFromObjects([SELECT Id, Contract__c, Quote__c, Contract__r.SBQQ__Quote__r.Total_deal_size_Workstations__c, Contract__r.SBQQ__Quote__r.Total_deal_size_Sq_ft__c FROM ContractToQuote__c WHERE Quote__c IN :quotesMappedById.keySet()], 'Quote__c');
        for (SBQQ__Quote__c quote : quotes) {
            quote.Net_Fill_Sq_ft__c = quote.Total_deal_size_Sq_ft__c;
            quote.Net_Fill_Workstations__c = quote.Total_deal_size_Workstations__c;
            if (contractToQuoteMappedByQuoteId.containsKey(quote.Id)) {
                for (ContractToQuote__c contractToQuote : contractToQuoteMappedByQuoteId.get(quote.Id)) {
                    quote.Net_Fill_Sq_ft__c -= NumberUtils.convertNullToZero(contractToQuote.Contract__r.SBQQ__Quote__r.Total_deal_size_Sq_ft__c);
                    quote.Net_Fill_Workstations__c -= NumberUtils.convertNullToZero(contractToQuote.Contract__r.SBQQ__Quote__r.Total_deal_size_Workstations__c);
                }
            }
        }
    }

    private static Boolean isHeadLineProduct(SBQQ__QuoteLine__c line) {
        return line.SBQQ__Bundle__c;
    }

    private static Boolean isLineRelatedToSpecifiedInventoryRecordTypes(SBQQ__QuoteLine__c line, Set<String> inventoryRecordTypeDeveloperNames) {
        return line.Suite_Inventory__c != null && line.Suite_Inventory__r.RecordType != null && inventoryRecordTypeDeveloperNames.contains(line.Suite_Inventory__r.RecordType.DeveloperName);
    }

    /**
     * @description Sets specified status to quote
     */
    public static void updateQuotesStatuses(Map<Id, String> quoteIdToStatusMap) {
        if (!quoteIdToStatusMap.isEmpty()) {
            List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
            for (Id quoteId : quoteIdToStatusMap.keySet()) {
                if (quoteId != null) {
                    quotes.add(new SBQQ__Quote__c(
                            Id = quoteId,
                            SBQQ__Status__c = quoteIdToStatusMap.get(quoteId)
                    ));
                }
            }
            update quotes;
        }
    }

    public static List<SBQQ__QuoteLine__c> getHeadLinesFromQLI(List<SBQQ__QuoteLine__c> items, Id quoteId) {
        List<SBQQ__QuoteLine__c> itemsList = new List<SBQQ__QuoteLine__c>(items);

        for (SBQQ__QuoteLine__c item : items) {

            if (item.SBQQ__RequiredBy__c == null && item.SBQQ__Bundle__c && item.SBQQ__Quote__c == quoteId) {
                itemsList.add(item);
            }
        }
        return itemsList;
    }

    public static List<SBQQ__QuoteLine__c> getQuoteLinesByQuoteIds(Set<Id> quoteIds) {
        List<SBQQ__QuoteLine__c> output = new List<SBQQ__QuoteLine__c>();
        if (!quoteIds.isEmpty()) {
            output = [
                    SELECT Id, SBQQ__Quantity__c, Bundle_Code__c, SBQQ__Bundle__c, Net_Subtotal__c, Break_Penalty__c, Deposit_Payment__c,
                            Net_Total__c, Percentage_Upfront__c, SBQQ__BillingType__c, SBQQ__BillingFrequency__c, CurrencyIsoCode,
                            SBQQ__Description__c, Deposit_Amount__c, Break_Date__c, Quanta__c, SBQQ__ProductCode__c, Discount_Percent__c,
                            Cap_Amount__c, Lease_Start_Date__c, Term__c, Comparable_ID_for_Calculator__c, Rent_Review_Type__c, IsConcession__c,
                            Guarantor_Name__c, Company_Number__c, Type_of_Guarantor__c, Maximum_Notice__c, Minimum_Notice__c, Registered_Address__c,
                            Licence_Start_Date__c, Start_Date__c, End_Date__c, Date__c,Cap_Per_sq_ft__c, Square_Footage__c,Updated_Price_per_sq_ft__c,
                            Cost_per_Sq_Ft_Annual__c, Non_Billable_Product__c,Rent_Review_Date__c,

                            SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Account__c, SBQQ__Quote__r.Property__c,
                            SBQQ__Quote__r.Property__r.Company__c, SBQQ__Quote__r.Property__r.Company_Name__c,
                            SBQQ__Quote__r.SBQQ__Opportunity2__r.RecordTypeId,

                            SBQQ__Product__c, SBQQ__Product__r.Name, SBQQ__ProductFamily__c, SBQQ__Product__r.Non_Billable_Product__c,
                            SBQQ__Product__r.SBQQ__BillingType__c, SBQQ__Product__r.SBQQ__BillingFrequency__c,
                            SBQQ__Product__r.c2g__CODASalesRevenueAccount__r.c2g__ReportingCode__c, SBQQ__Product__r.Override_GLA__c,
                            SBQQ__Product__r.c2g__CODATaxCode__c, SBQQ__Product__r.c2g__CODATaxCode__r.Name, SBQQ__Product__r.Is_Deposit__c,
                            SBQQ__Product__r.IsConcession__c, SBQQ__Product__r.Is_Insurance__c, SBQQ__Product__r.ProductCode,

                            SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQ__ProductCode__c,

                            Inventory__c, Inventory__r.RecordTypeId, Inventory__r.RecordType.Name, Inventory__r.Workstations__c,

                            Suite_Inventory__c, Suite_Inventory__r.Product__c, Suite_Inventory__r.Product__r.Name,
                            Suite_Inventory__r.Product__r.Family, Suite_Inventory__r.Size_sq_ft__c,
                            Suite_Inventory__r.RecordType.DeveloperName, Suite_Inventory__r.Workstations__c,

                            Car_Parking_Inventory__c, Car_Parking_Inventory__r.Name
                    FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c IN :quoteIds
            ];
        }
        return output;
    }

    public static Map<Id, Property__c> getPropertiesFromQuotes(List<SBQQ__Quote__c> quotes) {
        Set<Id> propertiesIds = SObjectUtils.getIdSetFromObjects(quotes, 'Property__c');
        Set<Id> propertiesToSelect = new Set<Id>();

        for (Id propertyId : propertiesIds) {
            if (!SBQQ_QuoteService.propertiesFromQuotes.containsKey(propertyId)) {
                propertiesToSelect.add(propertyId);
            }
        }

        if (!propertiesToSelect.isEmpty()) {
            for (Property__c prop : [
                    SELECT Id, Property_Manager__c, Serviced_Space_Coordinator__c, Company__c, Company_Name__c
                    FROM Property__c
                    WHERE Id IN :propertiesToSelect
            ]) {
                SBQQ_QuoteService.propertiesFromQuotes.put(prop.Id, prop);
            }
        }
        return SBQQ_QuoteService.propertiesFromQuotes;
    }

    public static Map<Id, Opportunity> getOpportunitiesFromQuotes(List<SBQQ__Quote__c> quotes) {
        Set<Id> opportunityIds = SObjectUtils.getIdSetFromObjects(quotes, 'SBQQ__Opportunity2__c');
        Set<Id> opportunitiesToSelect = new Set<Id>();

        for (Id opportunityId : opportunityIds) {
            if (!SBQQ_QuoteService.opportunitiesFromQuotes.containsKey(opportunityId)) {
                opportunitiesToSelect.add(opportunityId);
            }
        }

        if (!opportunitiesToSelect.isEmpty()) {
            for (Opportunity opp : [
                    SELECT Id, AccountId, Name, Description, Pricebook2Id, Briefing_Statement__c, Move_in_Wish_Date__c, RecordTypeId
                    FROM Opportunity
                    WHERE Id IN :opportunitiesToSelect
            ]) {
                SBQQ_QuoteService.opportunitiesFromQuotes.put(opp.Id, opp);
            }
        }
        return SBQQ_QuoteService.opportunitiesFromQuotes;
    }

    public static Map<Id, List<SBQQ__QuoteLine__c>> getQuoteLinesMap(List<SBQQ__Quote__c> quotes) {
        Set<Id> quoteIds = SObjectUtils.getIdSetFromObjects(quotes, 'Id');
        Set<Id> quoteIdsToSelect = new Set<Id>();

        for (Id quoteId : quoteIds) {
            if (!SBQQ_QuoteService.quoteLinesByQuoteIds.containsKey(quoteId)) {
                quoteIdsToSelect.add(quoteId);
            }
        }

        if (!quoteIdsToSelect.isEmpty()) {
            List<SBQQ__QuoteLine__c> quoteLines = SBQQ_QuoteService.getQuoteLinesByQuoteIds(quoteIdsToSelect);

            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                Id quoteId = quoteLine.SBQQ__Quote__c;

                if (!SBQQ_QuoteService.quoteLinesByQuoteIds.containsKey(quoteId)) {
                    SBQQ_QuoteService.quoteLinesByQuoteIds.put(quoteId, new List<SBQQ__QuoteLine__c>());
                }
                SBQQ_QuoteService.quoteLinesByQuoteIds.get(quoteId).add(quoteLine);
            }
        }
        return quoteLinesByQuoteIds;
    }

    public static List<SBQQ__QuoteLine__c> getHeadLinesItems(Id quoteId) {
        return getHeadLinesItems(new Set<Id>{
                quoteId
        });
    }

    public static List<SBQQ__QuoteLine__c> getHeadLinesItems(Set<Id> quoteIds) {
        return [
                SELECT Id, SBQQ__Quote__c, Tolerance_Level__c, SBQQ__ProductCode__c,
                        Inventory__c, Term_Certain__c, Term_Concessions__c,
                        Term__c, Rent_per_Sq_Ft_annual__c, Updated_Price_per_sq_ft__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
                AND SBQQ__RequiredBy__c = null
                AND SBQQ__Bundle__c = true
        ];
    }

    public static List<SBQQ__QuoteLine__c> getHeadLineSuiteItems(Id quoteId) {
        return getHeadLineSuiteItems(new Set<Id>{
                quoteId
        });
    }

    public static List<SBQQ__QuoteLine__c> getHeadLineSuiteItems(Set<Id> quoteIds) {
        return [
                SELECT Id, SBQQ__Quote__c, Tolerance_Level__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
                AND SBQQ__ProductFamily__c = :ProductService.PRODUCT_FAMILY_SUITE
                AND SBQQ__Bundle__c = true
        ];
    }

    public static Boolean isHeadLineProductAdded(List<SBQQ__QuoteLine__c> quoteLines, String productCode) {
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.SBQQ__Bundle__c == true && quoteLine.SBQQ__ProductCode__c == productCode) {
                return true;
            }
        }
        return false;
    }

    public static Set<Id> findSoldInventoryIdsFromQuoteLines(Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteIds) {
        Set<Id> soldInventoryIds = new Set<Id>();
        for (List<SBQQ__QuoteLine__c> quoteLines : quoteLinesByQuoteIds.values()) {
            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                if (quoteLine.Inventory__c != null) {
                    soldInventoryIds.add(quoteLine.Inventory__c);
                } else if (quoteLine.Suite_Inventory__c != null) {
                    soldInventoryIds.add(quoteLine.Suite_Inventory__c);
                }
            }
        }
        return soldInventoryIds;
    }

    public static Map<Id, Integer> getNumberOfInventorySuite(Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteIds) {
        Map<Id, Integer> outputMap = new Map<Id, Integer>();

        for (List<SBQQ__QuoteLine__c> quoteLines : quoteLinesByQuoteIds.values()) {
            for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
                System.debug('#####Quote line:' + quoteLine);
                //TODO: should also work for desks(comment from Vova). Story 300 should be updated
                if (quoteLine.Inventory__c != null && quoteLine.Inventory__r.RecordType != null && quoteLine.Inventory__r.RecordType.Name.contains('Suite')) {
                    Integer val = outputMap.get(quoteLine.SBQQ__Quote__c);
                    val = val == null ? 1 : val + 1;
                    outputMap.put(quoteLine.SBQQ__Quote__c, val);
                }
            }
        }
        System.debug('#####outputMap:' + outputMap);
        return outputMap;
    }

    /**
     * @description Returns a set of Ids where RecordType.DeveloperName starts with specified name
     */
    private static Set<Id> getRecordTypeIdsByName(String recordTypeName) {
        Set<Id> output = new Set<Id>();
        for (RecordType recordType : getRecrodTypes().values()) {
            if (recordType.DeveloperName.startsWith(recordTypeName)) {
                output.add(recordType.Id);
            }
        }
        return output;
    }

    public static void cleanup() {
        propertiesFromQuotes = new Map<Id, Property__c>();
        opportunitiesFromQuotes = new Map<Id, Opportunity>();
        quoteLinesByQuoteIds = new Map<Id, List<SBQQ__QuoteLine__c>>();
    }

    public static Id getBWCountersignUserId() {
        SBQQDS__DocuSignQuoteQuicklySettings__c docusignSettings = SBQQDS__DocuSignQuoteQuicklySettings__c.getOrgDefaults();
        return docusignSettings != null && docusignSettings.BW_Countersign_User_Id__c != null ? docusignSettings.BW_Countersign_User_Id__c : null;
    }

    public static void withdrawFromApprovalProcess(List<SBQQ__Quote__c> quotes) {
        Map<Id, List<ProcessInstanceWorkitem>> workItemsMappedByQuoteId = new Map<Id, List<ProcessInstanceWorkitem>>();
        Set<Id> quoteIds = SObjectUtils.getIdSetFromObjects(quotes, 'Id');
        List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, OriginalActorId, ProcessInstance.TargetObjectId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId IN :quoteIds
                AND ProcessInstance.Status = 'Pending'
        ];
        for (ProcessInstanceWorkitem workItem : workItems) {
            if (!workItemsMappedByQuoteId.containsKey(workItem.ProcessInstance.TargetObjectId)) {
                workItemsMappedByQuoteId.put(workItem.ProcessInstance.TargetObjectId, new List<ProcessInstanceWorkitem>{
                        workItem
                });
            } else {
                workItemsMappedByQuoteId.get(workItem.ProcessInstance.TargetObjectId).add(workItem);
            }
        }
        EmailHelper.sendEmailsToApprovers(workItemsMappedByQuoteId, EmailHelper.QUOTE_UNLOCKED_EMAIL_TEMPLATE);
        for (Id quoteId : workItemsMappedByQuoteId.keySet()) {
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction(SBQQ_QuoteApprovalHandler.APPROVAL_ACTION_REMOVED);
            pwr.setWorkItemId(workItemsMappedByQuoteId.get(quoteId).get(0).Id);
            Approval.process(pwr);
        }
    }
}