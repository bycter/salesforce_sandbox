public with sharing class ContractFromQuoteCreator {

    private static final Integer CONTRACT_NAME_MAX_LENGTH = 80;

    private static Map<String, String> generalLedgersToOverride;
    private static Map<String, Id> companyNameToCompanyErpId = new Map<String, Id>();

    public static void createContractWithSubscriptions(Map<Id, SBQQ__Quote__c> acceptedQuotesMap) {
        Map<Id, Opportunity> opportunityMap = SBQQ_QuoteService.getOpportunitiesFromQuotes(acceptedQuotesMap.values());
        Map<Id, Property__c> propertyMap = SBQQ_QuoteService.getPropertiesFromQuotes(acceptedQuotesMap.values());

        prepareMapCompanyNameToCompanyErpId(propertyMap.values());

        // select all QLI
        List<SBQQ__QuoteLine__c> lineItems = new List<SBQQ__QuoteLine__c>();
        Map<Id, List<SBQQ__QuoteLine__c>> linesMap = SBQQ_QuoteService.getQuoteLinesMap(acceptedQuotesMap.values());
        for (List<SBQQ__QuoteLine__c> lines : linesMap.values()) {
            lineItems.addAll(lines);
        }

        Map<Id, Contract> quoteIdContractMap = new Map<Id, Contract>();
        //Contracts creation
        for (Id quoteId : acceptedQuotesMap.keySet()) {
            SBQQ__Quote__c quote = acceptedQuotesMap.get(quoteId);
            Opportunity opportunity = opportunityMap.get(quote.SBQQ__Opportunity2__c);
            Property__c property = propertyMap.get(quote.Property__c);
            Contract contract = generateContract(quote, opportunity, property, lineItems);
            quoteIdContractMap.put(quoteId, contract);
        }
        //insert created contracts
        insert quoteIdContractMap.values();

        List<Opportunity> opportunityForUpdate = new List<Opportunity>();

        //populate last created contract field
        for (SBQQ__Quote__c quote : acceptedQuotesMap.values()) {
            Id contractId = quoteIdContractMap.get(quote.Id).Id;
            quote.Contract__c = contractId;
            opportunityForUpdate.add(new Opportunity(Id = quote.SBQQ__Opportunity2__c, ContractId = contractId));
        }
        // update opportunity
        update opportunityForUpdate;

        //Ad-Hoc Revenue creation
        Map<Id, Ad_hoc_Revenue__c> adHocRevenuesByQuoteLineIds = new Map<Id, Ad_hoc_Revenue__c>();

        //create new Ad-hoc Revenue per quote line
        for (SBQQ__QuoteLine__c quoteLine : lineItems) {
            if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_UPFRONT ||
                    quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_PARTIALUPFRONT) {
                Ad_hoc_Revenue__c adHocRevenueMap = generateAdHocRevenue(quoteLine);
                adHocRevenuesByQuoteLineIds.put(quoteLine.Id, adHocRevenueMap);
            }
        }

        if (!adHocRevenuesByQuoteLineIds.isEmpty()) {
            insert adHocRevenuesByQuoteLineIds.values();
        }

        //Subscriptions creation
        Map<Id, SBQQ__Subscription__c> subscriptions = new Map<Id, SBQQ__Subscription__c>(); // quote line to Subscription
        Map<Id, Contract> inventoryIdToContract = new Map<Id, Contract>();

        for (SBQQ__QuoteLine__c quoteLine : lineItems) {
            Id quoteId = quoteLine.SBQQ__Quote__c;
            if (acceptedQuotesMap.containsKey(quoteId) && quoteIdContractMap.containsKey(quoteId)) {
                SBQQ__Quote__c quoteLineQuote = acceptedQuotesMap.get(quoteId);
                Contract contract = quoteIdContractMap.get(quoteId);

                Ad_hoc_Revenue__c adHocRevenue = adHocRevenuesByQuoteLineIds.get(quoteLine.Id);

                //create new subscription per quote line
                SBQQ__Subscription__c subscription = generateSubscription(quoteLine, contract, quoteLineQuote, adHocRevenue);

                if (quoteLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_CAR_SPACE) {
                    contract.Total_Licensed_Parking_Spaces__c += quoteLine.SBQQ__Quantity__c;
                }
                if (quoteLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_CAR_PARKING_LEASE) {
                    contract.Total_Lease_Parking_Spaces__c += quoteLine.SBQQ__Quantity__c;
                }

                if ((quoteLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_DEPOSIT
                        || quoteLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_DEPOSIT_RETAIN)
                        && quoteLine.Net_Total__c != NULL) {
                    contract.Deposit_required_Value__c = quoteLine.Net_Total__c;
                }
                subscriptions.put(quoteLine.Id, subscription);

                if (quoteLine.Inventory__c != null) {
                    inventoryIdToContract.put(quoteLine.Inventory__c, contract);
                }
            }
        }
        if (!subscriptions.isEmpty()) {
            insert subscriptions.values();
        }

        // update Headline_Product lookup on subscriptions
        for (SBQQ__QuoteLine__c quoteLine : lineItems) {
            if (subscriptions.containsKey(quoteLine.SBQQ__RequiredBy__c)) {
                subscriptions.get(quoteLine.Id).Headline_Product__c = subscriptions.get(quoteLine.SBQQ__RequiredBy__c).Id;
            }
        }
        update subscriptions.values();

        upsert quoteIdContractMap.values();

        updateInventoriesWithNewContract(inventoryIdToContract);

        copyCompletedDocumentsFromQuotesToContracts(quoteIdContractMap.keySet());
    }

    private static void prepareMapCompanyNameToCompanyErpId(List<Property__c> properties) {
        Set<String> companyNames = new Set<String>();
        for (Property__c property : properties) {
            if (property.Company__c != null) {
                companyNames.add(property.Company_Name__c);
            }
        }
        for (fferpcore__Company__c company : [SELECT Id, Name FROM fferpcore__Company__c WHERE Name IN :companyNames]) {
            companyNameToCompanyErpId.put(company.Name, company.Id);
        }
    }

    private static void initGeneralLedgerOverride() {
        generalLedgersToOverride = new Map<String, String>();
        for (General_Ledger_Override__mdt glo : [
                SELECT Product_Code__c, Override_Value__c
                FROM General_Ledger_Override__mdt
        ]) {
            generalLedgersToOverride.put(glo.Product_Code__c, glo.Override_Value__c);
        }
    }

    private static String getReportingCodeToOverride(SBQQ__QuoteLine__c quoteLine) {
        if (generalLedgersToOverride == null) {
            initGeneralLedgerOverride();
        }

        String reportingCode = null;
        Product2 qlProduct = quoteLine.SBQQ__Product__r;
        String headlineProductCode = quoteLine.SBQQ__RequiredBy__r != null ? quoteLine.SBQQ__RequiredBy__r.SBQQ__ProductCode__c : quoteLine.SBQQ__ProductCode__c;
        if (qlProduct != null
                && qlProduct.Override_GLA__c
                && qlProduct.c2g__CODASalesRevenueAccount__r != null
                && generalLedgersToOverride.containsKey(headlineProductCode)) {
            reportingCode = qlProduct.c2g__CODASalesRevenueAccount__r.c2g__ReportingCode__c + '.' + generalLedgersToOverride.get(headlineProductCode);
        }
        return reportingCode;
    }

    private static Contract generateContract(SBQQ__Quote__c quote, Opportunity opportunity, Property__c property, List<SBQQ__QuoteLine__c> quoteLines) {
        Contract contract = new Contract();
        contract.OwnerId = quote.OwnerId;
        contract.SBQQ__Quote__c = quote.Id;
        contract.SBQQ__Opportunity__c = opportunity.Id;
        contract.Pricebook2Id = quote.SBQQ__PriceBook__c;
        contract.AccountId = opportunity.AccountId;
        contract.CurrencyIsoCode = quote.CurrencyIsoCode;
        contract.Name = generateContractName(opportunity.Name, quote.Name);
        contract.Status = 'Draft';
        contract.Description = opportunity.Description;
        contract.Property__c = property.Id;
        contract.Total_Lease_Parking_Spaces__c = 0;
        contract.Total_Licensed_Parking_Spaces__c = 0;
        if (companyNameToCompanyErpId.containsKey(property.Company_Name__c)) {
            contract.Legal_Entity__c = companyNameToCompanyErpId.get(property.Company_Name__c);
        }

        List<SBQQ__QuoteLine__c> quoteHeadLines = SBQQ_QuoteService.getHeadLinesFromQLI(quoteLines, quote.Id);
        for (SBQQ__QuoteLine__c headLine : quoteHeadLines) {
            Date startDate = headLine.Start_Date__c;
            if (headLine.SBQQ__ProductFamily__c == ProductService.PRODUCT_FAMILY_SUITE || (headLine.SBQQ__ProductFamily__c == ProductService.PRODUCT_FAMILY_PARKING
                    && contract.Contract_Term__c == NULL)) {
                contract.StartDate = startDate;
                contract.First_Bill_Date__c = startDate;
                contract.ContractTerm = (Integer) headLine.Term__c;
                contract.Contract_Term__c = headLine.Term__c;
            }
        }
        contract.Deposit_Not_Required__c = true;
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.SBQQ__Product__r.Is_Deposit__c) {
                contract.Deposit_required_Value__c = quoteLine.Net_Total__c;
                contract.Deposit_Paid_Value__c = quoteLine.Deposit_Payment__c;
                contract.Deposit_Not_Required__c = false;
                break;
            }
        }
        if (opportunity.RecordTypeId == RecordTypeHelper.getOpportunityRtIdByDeveloperName(OpportunityService.VIRTUAL_RECORD_TYPE_NAME)) {
            contract.Deposit_Not_Required__c = true;
        }
        if (contract.StartDate != null) {
            Date endDate = contract.StartDate.addMonths((Integer) contract.Contract_Term__c);
            contract.EndDate = endDate.addDays(-1);
        }
        return contract;
    }

    private static SBQQ__Subscription__c generateSubscription(SBQQ__QuoteLine__c quoteLine, Contract contract, SBQQ__Quote__c quote, Ad_hoc_Revenue__c adHocRevenue) {
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__QuoteLine__c = quoteLine.Id;
        subscription.OwnerId = quote.OwnerId;
        subscription.CurrencyIsoCode = quoteLine.CurrencyIsoCode;
        subscription.Override_GLA__c = getReportingCodeToOverride(quoteLine);

        //subscription.Backdated_Amount__c = ql.;//Think this is completed by Lease transactions
        //subscription.Backdated_Start_Date__c = ql.;//Think this is completed by Lease transactions

        //BWSFDC-1999
        if (isConcession(quoteLine)) {
            subscription.Stepped_Increase_Start_Date__c = quoteLine.Start_Date__c;
            subscription.Stepped_Increase_End_Date__c = quoteLine.End_Date__c;
        }

        subscription.First_Bill_Date__c = contract.First_Bill_Date__c;
        subscription.Stepped_Increase_Amount__c = quoteLine.Discount_Percent__c;//BWSFDC-1352 - FR1
        subscription.Rent_Review_Type__c = quoteLine.Rent_Review_Type__c;
        subscription.Guarantor_Name__c = quoteLine.Guarantor_Name__c;
        subscription.Company_Number__c = quoteLine.Company_Number__c;
        subscription.Type_of_Guarantor__c = quoteLine.Type_of_Guarantor__c;
        subscription.Maximum_Notice__c = quoteLine.Maximum_Notice__c;
        subscription.Minimum_Notice__c = quoteLine.Minimum_Notice__c;
        subscription.Registered_Address__c = quoteLine.Registered_Address__c;
        subscription.Term__c = quoteLine.Term__c;
        subscription.Next_Review_Date__c = quoteLine.Rent_Review_Date__c;
        subscription.Cap_Per_sq_ft__c = quoteLine.Cap_Per_sq_ft__c;
        subscription.Square_Footage__c = quoteLine.Square_Footage__c;
        subscription.Rent_per_sq_ft__c = quoteLine.Updated_Price_per_sq_ft__c;
        subscription.Cost_per_sq_ft_pa__c = quoteLine.Cost_per_Sq_Ft_Annual__c;


        subscription.Description__c = quoteLine.SBQQ__Description__c;
        subscription.Property__c = quote.Property__c;
        subscription.Inventory__c = quoteLine.Inventory__c;
        if (quoteLine.Inventory__c != null) {
            subscription.Number_of_Workstations__c = quoteLine.Inventory__r.Workstations__c == null ? 0 : quoteLine.Inventory__r.Workstations__c;
        }
        subscription.Non_Billable_Product__c = quoteLine.Non_Billable_Product__c;
        subscription.IsInsurance__c = quoteLine.SBQQ__Product__r.Is_Insurance__c;
        subscription.Is_Insurance__c = quoteLine.SBQQ__Product__r.Is_Insurance__c;


        subscription.SBQQ__Account__c = quote.SBQQ__Account__c;
        subscription.SBQQ__Contract__c = contract.Id;
        subscription.SBQQ__BillingFrequency__c = quoteLine.SBQQ__BillingFrequency__c;
        subscription.SBQQ__BillingType__c = quoteLine.SBQQ__BillingType__c;
        subscription.SBQQ__Product__c = quoteLine.SBQQ__Product__c;
        subscription.SBQQ__Quantity__c = quoteLine.SBQQ__Quantity__c != null ? quoteLine.SBQQ__Quantity__c : 1;

        Double quantity = subscription.SBQQ__Quantity__c != 0 ? subscription.SBQQ__Quantity__c : 1;
        Double multiplier = getMultiplier(quoteLine);
        if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_UPFRONT) {
            subscription.SBQQ__UnitCost__c = 0;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_PARTIALUPFRONT
                && quoteLine.Percentage_Upfront__c != null && quoteLine.Net_Total__c != null) {
            subscription.SBQQ__UnitCost__c = quoteLine.Net_Total__c * (1 - quoteLine.Percentage_Upfront__c / 100) / quantity;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_WEEKLY) {
            subscription.SBQQ__UnitCost__c = multiplier / contract.Contract_Term__c * 12 / 52 / quantity;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_MONTHLY) {
            subscription.SBQQ__UnitCost__c = multiplier / contract.Contract_Term__c / quantity;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_QUARTERLY
                || quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_TRADITIONAL_QUARTERS) {
            subscription.SBQQ__UnitCost__c = multiplier / contract.Contract_Term__c * 3 / quantity;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_SEMIANNUAL) {
            subscription.SBQQ__UnitCost__c = multiplier / contract.Contract_Term__c * 6 / quantity;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_ANNUAL) {
            subscription.SBQQ__UnitCost__c = multiplier / contract.Contract_Term__c * 12 / quantity;
        } else if (String.isNotBlank(quoteLine.SBQQ__BillingFrequency__c)) {
            subscription.SBQQ__UnitCost__c = multiplier / quantity;
        }

        subscription.BreakDate__c = quoteLine.Break_Date__c != null && contract.StartDate != null ? contract.startDate.addMonths((Integer) quoteLine.Break_Date__c) : null;
        subscription.Break_Penalty__c = quoteLine.Break_Penalty__c;
        subscription.Cap_Amount__c = quoteLine.Cap_Amount__c;
        subscription.IsConcession__c = quoteLine.IsConcession__c;
        subscription.Ad_hoc_Revenue__c = adHocRevenue != null ? adHocRevenue.Id : null;

        subscription.SBQQ__SubscriptionStartDate__c = quoteLine.Start_Date__c != null ? quoteLine.Start_Date__c : contract.StartDate;
        subscription.SBQQ__SubscriptionEndDate__c = subscription.SBQQ__SubscriptionStartDate__c != null && quoteLine.Term__c != null ? subscription.SBQQ__SubscriptionStartDate__c.addMonths((Integer) quoteLine.Term__c).addDays(-1) : contract.EndDate;
        return subscription;
    }

    private static Boolean isConcession(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__ProductCode__c == QuoteProductCodes.STEPPED_RENT
                || quoteLine.SBQQ__ProductCode__c == QuoteProductCodes.HALF_RENT
                || quoteLine.SBQQ__ProductCode__c == QuoteProductCodes.RENT_FREE;
    }

    private static Double getMultiplier(SBQQ__QuoteLine__c quoteLine) {
        Double netTotal = NumberUtils.convertNullToZero(quoteLine.Net_Total__c);
        Double netSubtotal = NumberUtils.convertNullToZero(quoteLine.Net_Subtotal__c);

        Boolean isNotBundleProduct = quoteLine.SBQQ__RequiredBy__c != null && !quoteLine.SBQQ__Bundle__c;
        Boolean isParking = quoteLine.SBQQ__ProductFamily__c == ProductService.PRODUCT_FAMILY_PARKING;
        Boolean isConcessionProduct = quoteLine.SBQQ__Product__r.IsConcession__c;

        return isNotBundleProduct || isParking || isConcessionProduct ? netTotal : netSubtotal;
    }

    private static Ad_hoc_Revenue__c generateAdHocRevenue(SBQQ__QuoteLine__c quoteLine) {
        Ad_hoc_Revenue__c adHocRevenue = new Ad_hoc_Revenue__c();
        if (quoteLine.SBQQ__Quote__c != null
                && quoteLine.SBQQ__Quote__r.Property__c != null
                && quoteLine.SBQQ__Quote__r.Property__r.Company__c != null) {
            adHocRevenue.Legal_Entity__c = quoteLine.SBQQ__Quote__r.Property__r.Company_Name__c;
        }
        adHocRevenue.Customer_Account__c = quoteLine.SBQQ__Quote__r.SBQQ__Account__c;
        //adHocRevenue.Customer_Reference__c = 'Customer_Reference'; //TODO: will be implemented after Tobie answer in 1628 story
        adHocRevenue.CurrencyIsoCode = quoteLine.CurrencyIsoCode;
        adHocRevenue.Currency__c = 'GBP';
        adHocRevenue.Property__c = quoteLine.SBQQ__Quote__r.Property__c;
        adHocRevenue.Due_Date__c = Date.today() + SBQQ_QuoteConstants.DUE_DATE_ESTIMATION;
        adHocRevenue.Invoice_Date__c = Date.today();
        //adHocRevenue.Invoice_Description__c = 'Invoice Description'; //TODO: will be implemented after Tobie answer in 1628 story
        //adHocRevenue.Period__c = 'Period'; //TODO: will be implemented after Tobie answer in 873 or 1628 story
        adHocRevenue.Product__c = quoteLine.SBQQ__Product__c;
        adHocRevenue.Quantity__c = quoteLine.SBQQ__Quantity__c;
        if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_UPFRONT) {
            adHocRevenue.Unit_Price__c = quoteLine.Net_Total__c;
        } else if (quoteLine.SBQQ__BillingFrequency__c == SBQQ_QuoteConstants.BILLINGFREQUENCY_PARTIALUPFRONT
                && quoteLine.Net_Total__c != null && quoteLine.Percentage_Upfront__c != null) {
            adHocRevenue.Unit_Price__c = quoteLine.Net_Total__c * quoteLine.Percentage_Upfront__c / 100;
        }
        if (quoteLine.SBQQ__Product__r.c2g__CODATaxCode__r != null) {
            adHocRevenue.Tax_Code__c = quoteLine.SBQQ__Product__r.c2g__CODATaxCode__r.Name;
        }
        adHocRevenue.Document_Type__c = quoteLine.SBQQ__ProductCode__c == QuoteProductCodes.CAPEX_CONTRIBUTION ? 'Credit Note' : 'Invoice';
        //adHocRevenue.From_Date__c = Date.today(); //TODO: will be implemented after Tobie answer in 1628 story
        //adHocRevenue.To_Date__c = Date.today(); //TODO: will be implemented after Tobie answer in 1628 story
        return adHocRevenue;
    }

    public static void updateInventoriesWithNewContract(Map<Id, Contract> inventoryIdContractMap) {
        if (!inventoryIdContractMap.isEmpty()) {
            List<Inventory__c> inventoriesToUpdate = new List<Inventory__c>();
            List<Contract_To_Inventory__c> contractRelations = new List<Contract_To_Inventory__c>();
            for (Id inventoryId : inventoryIdContractMap.keySet()) {
                if (inventoryIdContractMap.containsKey(inventoryId)) {
                    Contract contract = inventoryIdContractMap.get(inventoryId);
                    String contractId = contract.Id;
                    inventoriesToUpdate.add(new Inventory__c(
                            Id = inventoryId,
                            Customer__c = contract.AccountId
                    ));

                    // to avoid duplications
                    contractRelations.add(new Contract_To_Inventory__c(
                            Contract__c = contractId,
                            Inventory__c = inventoryId,
                            External_Id__c = inventoryId + contractId
                    ));
                }
            }
            update inventoriesToUpdate;
            Database.upsert(contractRelations, Contract_To_Inventory__c.External_Id__c, false);
        }
    }

    public static void copyCompletedDocumentsFromQuotesToContracts(Set<Id> quotesIds) {
        if (!quotesIds.isEmpty()) {
            Set<Id> quoteDocumentsIds = new Map<Id, SBQQ__QuoteDocument__c>([SELECT Id FROM SBQQ__QuoteDocument__c WHERE SBQQ__Quote__c IN :quotesIds]).keySet();

            List<Attachment> attachments = [
                    select Body, BodyLength, ContentType, Description, Name, OwnerId, ParentId
                    from Attachment
                    where ParentId in :quoteDocumentsIds
            ];
            QuoteAttachmentUtils.associateAttachmentFromQuoteDocumentsWithRelatedContract(attachments);
        }
    }

    private static String generateContractName(String opportunityName, String quoteName) {
        String contractName = opportunityName + ' & ' + quoteName;
        if (contractName.length() > CONTRACT_NAME_MAX_LENGTH) {
            contractName = contractName.abbreviate(CONTRACT_NAME_MAX_LENGTH);
        }
        return contractName;
    }
}