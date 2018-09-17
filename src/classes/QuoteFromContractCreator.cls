public with sharing class QuoteFromContractCreator {
    public static final String[] HEADLINE_PRODUCT_CODES = new String[]{
            'LabSpace', 'OfficeRent', 'RetailRent', 'BSLF', 'BSCW', 'BSDL', 'BVLF', 'BVLM'
    };

    public static final String[] UNIQUE_NONSUITE_PRODUCT_CODES = new String[]{
            'CarParkLicense'
    };

    public static SBQQ__Quote__c generate(Opportunity opportunity, Id masterContractId, List<String> selectedContractsIds, String quoteType) {
        //TODO: check for invalid data!

        Map<Id, Contract> contracts = new Map<Id, Contract>([
                SELECT Id, SBQQ__Quote__c, Name, ContractTerm, Contract_Term__c, StartDate
                FROM Contract
                WHERE Id IN :selectedContractsIds
        ]);
        Contract masterContract = contracts.get(masterContractId);

        Set<Id> quotesIds = new Set<Id>();
        for (Contract c : contracts.values()) {
            quotesIds.add(c.SBQQ__Quote__c);
        }

        Map<Id, SBQQ__Quote__c> existingQuotesMap = findExistingQuotesByIds(quotesIds);

        SBQQ__Quote__c newQuote = null;
        if (existingQuotesMap.containsKey(masterContract.SBQQ__Quote__c)) {
            newQuote = existingQuotesMap.get(masterContract.SBQQ__Quote__c).clone(false, true);
        } else {
            newQuote = new SBQQ__Quote__c(); //BWSFDC-2289
        }
        newQuote.RecordTypeId = RecordTypeHelper.getSbqqQuoteRtIdByDeveloperName(opportunity.RecordType.DeveloperName);
        newQuote.SBQQ__Status__c = 'Draft';
        newQuote.SBQQ__Type__c = quoteType;
        newQuote.SBQQ__Opportunity2__c = opportunity.Id;
        newQuote.Legacy_contract__c = masterContract.Id;
        newQuote.SBQQ__BillingName__c = opportunity.Account.Name;
        newQuote.SBQQ__ShippingName__c = opportunity.Account.Name;
        newQuote.No_Viewing_Required_Comment__c = newQuote.SBQQ__Type__c.replace('_', ' ');
        insert newQuote;
        SBQQ.TriggerControl.disable();
        newQuote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Id = :newQuote.Id];

        createContractQuoteJunction(newQuote, contracts.values());

        Id masterSuiteQuoteLineId = findMasterQuoteLineId(masterContract.SBQQ__Quote__c);
        Set<Id> masterUniqueNonSuiteHeadlinesIds = findMasterUniqueNonSuiteHeadlinesIds(masterContract.SBQQ__Quote__c);

        Map<Id, SBQQ__QuoteLine__c> oldQuoteLinesMap = findQuoteLines(existingQuotesMap.keySet());

        Map<Id, SBQQ__QuoteLine__c> oldLineIdToNewLineMap = new Map<Id, SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c oldQuoteLine : oldQuoteLinesMap.values()) {
            if (isParentSecondHeadline(oldQuoteLine, masterSuiteQuoteLineId, oldQuoteLinesMap)
                    || isParentUniqueHeadline(oldQuoteLine, masterUniqueNonSuiteHeadlinesIds, oldQuoteLinesMap)) {
                continue;
            }
            SBQQ__QuoteLine__c newQuoteLine = oldQuoteLine.clone(false, true);
            newQuoteLine.SBQQ__Quote__c = newQuote.Id;
            oldLineIdToNewLineMap.put(oldQuoteLine.Id, newQuoteLine);
        }

        insert oldLineIdToNewLineMap.values();

        removeUnnecessaryQLIs(existingQuotesMap.keySet(), masterSuiteQuoteLineId, oldLineIdToNewLineMap);
        //try to update quote lines
        updateQuoteLinesWithValuesFromSubscriptions(contracts.keySet(), oldLineIdToNewLineMap, masterContract.Contract_Term__c);

        SBQQ.TriggerControl.enable();
        return newQuote;
    }

    //this method removes child qli with requiredBy=secondary headline
    private static void removeUnnecessaryQLIs(Set<Id> quotesIds, Id masterSuiteQuoteLineId, Map<Id, SBQQ__QuoteLine__c> oldLineIdToNewLineMap) {
        Set<Id> quoteLinesIdsToRemove = new Map<Id, SBQQ__QuoteLine__c>([SELECT Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quotesIds AND SBQQ__ProductCode__c IN :HEADLINE_PRODUCT_CODES]).keySet();
        quoteLinesIdsToRemove.remove(masterSuiteQuoteLineId);

        List<SBQQ__QuoteLine__c> qlToRemove = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c newLine : oldLineIdToNewLineMap.values()) {
            if (quoteLinesIdsToRemove.contains(newLine.SBQQ__RequiredBy__c)) {
                qlToRemove.add(newLine);
                continue;
            }

            if (newLine.SBQQ__RequiredBy__c != null && oldLineIdToNewLineMap.get(newLine.SBQQ__RequiredBy__c) != null) {
                newLine.SBQQ__RequiredBy__c = oldLineIdToNewLineMap.get(newLine.SBQQ__RequiredBy__c).Id;
            }
            if (newLine.SBQQ__Source__c != null && oldLineIdToNewLineMap.get(newLine.SBQQ__Source__c) != null) {
                newLine.SBQQ__Source__c = oldLineIdToNewLineMap.get(newLine.SBQQ__Source__c).Id;
            }
        }
        delete qlToRemove;
    }

    private static void updateQuoteLinesWithValuesFromSubscriptions(Set<Id> contractsIds, Map<Id, SBQQ__QuoteLine__c> oldLineIdToNewLineMap, Decimal ContractTerm) {
        List<SBQQ__Subscription__c> subscriptions = [
                SELECT Id, SBQQ__Product__c, Inventory__c, SBQQ__QuoteLine__c
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c IN :contractsIds
        ];

        for (SBQQ__Subscription__c subscription : subscriptions) {
            SBQQ__QuoteLine__c quoteLine = oldLineIdToNewLineMap.get(subscription.SBQQ__QuoteLine__c);
            if (quoteLine != null) {
                quoteLine.SBQQ__Product__c = subscription.SBQQ__Product__c;
                quoteLine.Inventory__c = subscription.Inventory__c;
                if (quoteLine.Suite_Inventory__c != null) {
                    quoteLine.Suite_Inventory__c = subscription.Inventory__c;
                }
                if (quoteLine.Car_Parking_Inventory__c != null) {
                    quoteLine.Car_Parking_Inventory__c = subscription.Inventory__c;
                }
                if (quoteLine.SBQQ__RequiredBy__c == null) {
                    quoteLine.Term__c = contractTerm;
                    quoteLine.Headline_Item_Subscription_Term__c = contractTerm;
                }
            }
        }
        update oldLineIdToNewLineMap.values();
    }

    private static Map<Id, SBQQ__Quote__c> findExistingQuotesByIds(Set<Id> quotesIds) {
        return new Map<Id, SBQQ__Quote__c>([
                SELECT Id, SBQQ__Account__c, SBQQ__Opportunity2__c, RecordTypeId, SBQQ__PriceBook__c, SBQQ__Type__c,
                        Property__c, SBQQ__BillingName__c,SBQQ__ShippingName__c, SBQQ__Status__c, SBQQ__PrimaryContact__c,
                        Secondary_Signature__c, BW_Signature_User__c
                FROM SBQQ__Quote__c
                WHERE Id IN :quotesIds
        ]);
    }

    private static void createContractQuoteJunction(SBQQ__Quote__c quote, List<Contract>contracts) {
        List<ContractToQuote__c> junctions = new List<ContractToQuote__c>();
        for (Contract contract : contracts) {
            String name = contract.Name + ' To ' + quote.Name;
            junctions.add(new ContractToQuote__c(Name = name, Quote__c = quote.Id, Contract__c = contract.Id));
        }
        insert junctions;
    }

    //TODO:refactor
    private static Boolean isParentSecondHeadline(SBQQ__QuoteLine__c quoteLine, Id primaryHeadlineId, Map<Id, SBQQ__QuoteLine__c> oldQuoteLines) {
        if (quoteLine.Id == primaryHeadlineId || quoteLine.SBQQ__RequiredBy__c == primaryHeadlineId) {
            return false;
        } else if (quoteLine.SBQQ__RequiredBy__c == null && quoteLine.SBQQ__Product__c != null && HEADLINE_PRODUCT_CODES.contains(quoteLine.SBQQ__ProductCode__c)) {
            return true;
        } else if (quoteLine.SBQQ__RequiredBy__c != null) {
            return isParentSecondHeadline(oldQuoteLines.get(quoteLine.SBQQ__RequiredBy__c), primaryHeadlineId, oldQuoteLines);
        }
        return false;
    }

    private static Boolean isParentUniqueHeadline(SBQQ__QuoteLine__c quoteLine, Set<Id> primaryLineIds, Map<Id, SBQQ__QuoteLine__c> oldQuoteLines) {
        if (primaryLineIds.contains(quoteLine.Id) || primaryLineIds.contains(quoteLine.SBQQ__RequiredBy__c)) {
            return false;
        } else if (quoteLine.SBQQ__RequiredBy__c == null && quoteLine.SBQQ__Product__c != null && UNIQUE_NONSUITE_PRODUCT_CODES.contains(quoteLine.SBQQ__ProductCode__c)) {
            return true;
        } else if (quoteLine.SBQQ__RequiredBy__c != null) {
            return isParentUniqueHeadline(oldQuoteLines.get(quoteLine.SBQQ__RequiredBy__c), primaryLineIds, oldQuoteLines);
        }
        return false;
    }

    private static Id findMasterQuoteLineId(Id quoteId) {
        List<SBQQ__QuoteLine__c> masterSuiteQuoteLines = [
                select Id
                from SBQQ__QuoteLine__c
                where SBQQ__Quote__c = :quoteId
                and SBQQ__ProductCode__c in :HEADLINE_PRODUCT_CODES
                and SBQQ__RequiredBy__c = null
        ];
        if (!masterSuiteQuoteLines.isEmpty()) {
            return masterSuiteQuoteLines.get(0).Id;
        } else {
            masterSuiteQuoteLines = [
                    select Id
                    from SBQQ__QuoteLine__c
                    where SBQQ__Quote__c = :quoteId
                    and SBQQ__RequiredBy__c = null
            ];
            if (!masterSuiteQuoteLines.isEmpty()) {
                return masterSuiteQuoteLines.get(0).Id;
            } else {
                return null;
            }
        }
    }

    private static Set<Id> findMasterUniqueNonSuiteHeadlinesIds(Id quoteId) {
        return new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND SBQQ__ProductCode__c IN :UNIQUE_NONSUITE_PRODUCT_CODES
                AND SBQQ__RequiredBy__c = NULL
        ]).keySet();
    }

    private static Map<Id, SBQQ__QuoteLine__c> findQuoteLines(Set<Id> quoteIds) {
        return new Map<Id, SBQQ__QuoteLine__c>([
                SELECT Id, IsDeleted, Name, CurrencyIsoCode, SBQQ__Quote__c, SBQQ__AdditionalDiscountAmount__c,
                        SBQQ__AdditionalDiscount__c, SBQQ__AdditionalQuantity__c, SBQQ__AllowAssetRefund__c,
                        SBQQ__BatchQuantity__c, SBQQ__BillingFrequency__c, SBQQ__BillingType__c, SBQQ__BlockPrice__c,
                        SBQQ__Bundle__c, SBQQ__BundledQuantity__c, SBQQ__Bundled__c, SBQQ__CarryoverLine__c,
                        SBQQ__ChargeType__c, SBQQ__CompletelyContracted__c, SBQQ__ComponentCost__c,
                        SBQQ__ComponentDiscountedByPackage__c, SBQQ__ComponentListTotal__c,
                        SBQQ__ComponentSubscriptionScope__c, SBQQ__ComponentTotal__c,
                        SBQQ__ComponentUpliftedByPackage__c, SBQQ__ComponentVisibility__c,
                        SBQQ__CompoundDiscountRate__c, SBQQ__ConfigurationRequired__c, SBQQ__ContractedPrice__c,
                        SBQQ__CostEditable__c, SBQQ__Cost__c, SBQQ__CustomerPrice__c, SBQQ__CustomerTotal__c,
                        SBQQ__DefaultSubscriptionTerm__c, SBQQ__Description__c, SBQQ__Dimension__c,
                        SBQQ__DiscountScheduleType__c, SBQQ__DiscountSchedule__c, SBQQ__DiscountTier__c,
                        SBQQ__Discount__c, SBQQ__DistributorDiscount__c, SBQQ__DynamicOptionId__c,
                        SBQQ__EffectiveEndDate__c, SBQQ__EffectiveQuantity__c, SBQQ__EffectiveStartDate__c,
                        SBQQ__EndDate__c, SBQQ__Existing__c, SBQQ__Favorite__c, SBQQ__GenerateContractedPrice__c,
                        SBQQ__GrossProfit__c, SBQQ__Group__c, SBQQ__Hidden__c, SBQQ__Incomplete__c, SBQQ__ListPrice__c,
                        SBQQ__ListTotal__c, SBQQ__MarkupAmount__c, SBQQ__MarkupRate__c, SBQQ__Markup__c,
                        SBQQ__MaximumPrice__c, SBQQ__MinimumPrice__c, SBQQ__NetPrice__c, SBQQ__NetTotal__c,
                        SBQQ__NonDiscountable__c, SBQQ__NonPartnerDiscountable__c, SBQQ__Number__c,
                        SBQQ__OptionDiscountAmount__c, SBQQ__OptionDiscount__c, SBQQ__OptionLevel__c,
                        SBQQ__OptionType__c, SBQQ__Optional__c, SBQQ__OriginalPrice__c, SBQQ__OriginalQuoteLineId__c,
                        SBQQ__OriginalUnitCost__c, SBQQ__PackageCost__c, SBQQ__PackageListTotal__c,
                        SBQQ__PackageProductCode__c, SBQQ__PackageProductDescription__c, SBQQ__PackageTotal__c,
                        SBQQ__PartnerDiscount__c, SBQQ__PartnerPrice__c, SBQQ__PartnerTotal__c,
                        SBQQ__PreviousSegmentPrice__c, SBQQ__PreviousSegmentUplift__c, SBQQ__PriceEditable__c,
                        SBQQ__PricingMethodEditable__c, SBQQ__PricingMethod__c, SBQQ__PriorQuantity__c,
                        SBQQ__ProductCode__c, SBQQ__ProductFamily__c, SBQQ__ProductName__c, SBQQ__ProductOption__c,
                        SBQQ__Product__c, SBQQ__ProrateMultiplier__c, SBQQ__ProratedListPrice__c,
                        SBQQ__ProratedPrice__c, SBQQ__Quantity__c, SBQQ__RegularPrice__c, SBQQ__RegularTotal__c,
                        SBQQ__Renewal__c, SBQQ__RenewedAsset__c, SBQQ__RenewedSubscription__c, SBQQ__RequiredBy__c,
                        SBQQ__SegmentIndex__c, SBQQ__SegmentKey__c, SBQQ__SegmentLabel__c, SBQQ__Source__c,
                        SBQQ__SpecialPriceDescription__c, SBQQ__SpecialPriceType__c, SBQQ__SpecialPrice__c,
                        SBQQ__StartDate__c, SBQQ__SubscribedAssetIds__c, SBQQ__SubscriptionBase__c,
                        SBQQ__SubscriptionCategory__c, SBQQ__SubscriptionPercent__c, SBQQ__SubscriptionPricing__c,
                        SBQQ__SubscriptionScope__c, SBQQ__SubscriptionTargetPrice__c, SBQQ__SubscriptionTerm__c,
                        SBQQ__TaxCode__c, SBQQ__Taxable__c, SBQQ__TermDiscountSchedule__c, SBQQ__TermDiscountTier__c,
                        SBQQ__TermDiscount__c, SBQQ__TotalDiscountAmount__c, SBQQ__TotalDiscountRate__c,
                        SBQQ__UnitCost__c, SBQQ__UnproratedNetPrice__c, SBQQ__UpgradedAsset__c,
                        SBQQ__UpgradedQuantity__c, SBQQ__UpgradedSubscription__c, SBQQ__UpliftAmount__c,
                        SBQQ__Uplift__c, SBQQ__VolumeDiscount__c, Actual_Date__c, Additional_Seats__c,
                        Additional_Services_Total__c, Amount_of_Workstations__c, Annual_Average_Without_Discount__c,
                        Annual_Average__c, Annual_Cost__c, Annual_Price_per_Sq_Ft__c, Break_Date__c, Break_Penalty__c,
                        Bundle_Code__c, Cap_Amount__c, Cap_Expiry_Month__c, Car_Parking_Inventory__c,
                        Comparable_ID_for_Calculator__c, Conducted_By__c, Customer_Price__c, DTC_Serv_CF__c,
                        DTC_Serv_Term__c, Date__c, Date_for_Comparison__c, Deposit_Already_Held__c, Deposit_Amount__c,
                        Deposit_Payment__c, Deposit_Q_L__c, Discount_Amount__c, Discount_Full_Term_Percent__c,
                        Discount_Full_Term__c, Discount_Percent__c, Discount_Term_Certain_Percent__c,
                        Discount_Term_Certain_Rollup__c, Discount_Term_Certain__c, Discount_Total__c, Due_Date__c,
                        Earliest_Break_Date__c, End_Date__c, End_Term__c, Floor_Number__c, Guarantor_Name__c,
                        Headline_Item_Subscription_Term__c, Indicative_Start_Date__c, Inventory_Cost_per_space__c,
                        Inventory_Estate_Charge_Total__c, Inventory_Ground_Rent_Charge_Total__c,
                        Inventory_Insurance_Charge_Total__c, Inventory_Rent_Total__c, Inventory_Rent_per_workstation__c,
                        Inventory_Service_Charge_Total__c, Inventory__c, Lease_Start_Date__c, Legal_Fees_Cap__c,
                        Level_of_Service__c, Line_Total_Price__c, List_Price_Cost_Per_Handset_PCM__c, List_Price__c,
                        Maintained_By__c, Maximum_Notice__c, Minimum_Notice__c, Monthly_Average_Without_Discount__c,
                        Monthly_Average__c, Monthly_Cost__c, Monthly_Cost_after_Discount__c, Monthly_Payment_Obsolete__c,
                        Monthly_Payment__c, Monthly_Total__c, Net_Subtotal__c, Net_Total__c, New_Annual_Average__c,
                        New_Monthly_Average__c, Notes__c, Number_of_Hours__c, Number_of_Rental_Months__c,
                        Percentage_Upfront__c, Period__c, Postcode__c, Price_Per_sq_ft__c, Product_for_Filter__c,
                        Project_Management_Fee__c, Property_Address__c, Property_for_Filter__c, Quanta__c,
                        Quote_Property__c, Registered_Address__c, Rent_Per_Workstation__c, Rent_Review_Anniversary__c,
                        Rent_Review_Type__c, Rent_Step_To__c, Required_Months_before_Notice__c,
                        Revised_Price_Cost_Per_Handset_PCM__c, Serviced_Internet_Bandwidth__c, Shared_Meter__c,
                        Square_Footage__c, Start_Date__c, Start_Term__c, Status__c, Subtotal__c, Suite_Inventory__c,
                        Suppliers_Contribution__c, Term_Certain__c, Term_Concessions__c, Term__c,
                        Tolerance_Is_Exceeded__c, Tolerance_State__c, Tolerance__c, Total__c, Type_of_Guarantor__c,
                        Updated_Monthly_Average__c, Updated_Price_per_sq_ft__c, Updated_Rent_Per_Workstation__c,
                        Value__c, When_to_Start_the_Term__c, Works_Prior_to_Lease_Start__c, Capital_Allowances__c,
                        Date_Balance_Due__c, Deposit_Monthly_Average__c, Fixed__c, Payable_by_customer__c,
                        Suite_Available_From_Date__c, Suite_Incumbent_End_Date__c, Suite_Incumbent_Start_Date__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c IN :quoteIds
        ]);
    }
}