public with sharing class DocumentGenerationHelper {
    public static final SobjectField START_CONCESSION_TERM_FIELD = SBQQ__QuoteLine__c.Start_Term__c;

    public static Map<String, List<SBQQ__QuoteLine__c>> getBundleProductMap(String code, List<SBQQ__QuoteLine__c> qliList) {
        Map<String, List<SBQQ__QuoteLine__c>> rentReviewMapBySuite = new Map<String, List<SBQQ__QuoteLine__c>>();

        for (SBQQ__QuoteLine__c qlHead : qliList) {
            //search for Headline
            if (isSuiteBundle(qlHead)) {
                List<SBQQ__QuoteLine__c> rentReviewList = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c ql : qliList) {
                    //search related products
                    if (ql.SBQQ__ProductCode__c == code &&
                            ql.SBQQ__RequiredBy__c == qlHead.Id) {

                        rentReviewList.add(ql);

                    }
                }

                rentReviewMapBySuite.put(qlHead.Id, rentReviewList);
            }
        }

        return rentReviewMapBySuite;

    }

    public static List<SBQQ__QuoteLine__c> addFullPriceSteps(List<SBQQ__QuoteLine__c> steppedList, SBQQ__QuoteLine__c headLine) {
        Integer counter = 0;
        List<SBQQ__QuoteLine__c> allStepsList = new List<SBQQ__QuoteLine__c>();
        if (steppedList.size() > 0) {
            SortSobs.ascending(steppedList, START_CONCESSION_TERM_FIELD);
            for (SBQQ__QuoteLine__c qLIStep : steppedList) {
                qLIStep.Monthly_Total__c = (headLine.Monthly_Average_Without_Discount__c * (1- qLIStep.Discount_Percent__c * 0.01)).setScale(2);
                if ((counter == 0 && qLIStep.Start_Term__c == 1) || (counter > 0  &&
                        qliStep.Start_Term__c == steppedList[counter - 1].Rent_Step_To__c)) {
                    allStepsList.add(qLIStep);
                } else if (counter == 0 && qLIStep.Start_Term__c > 1) {
                    allStepsList.add(new SBQQ__QuoteLine__c(Start_Term__c = 1, Rent_Step_To__c = qLIStep.Start_Term__c,
                            Monthly_Total__c = headLine.Monthly_Average_Without_Discount__c));
                    allStepsList.add(qLIStep);
                } else if (qliStep.Start_Term__c > steppedList[counter - 1].Rent_Step_To__c) {
                    allStepsList.add(new SBQQ__QuoteLine__c(Start_Term__c = steppedList[counter - 1].Rent_Step_To__c, Rent_Step_To__c = qLIStep.Start_Term__c,
                            Monthly_Total__c = headLine.Monthly_Average_Without_Discount__c));
                    allStepsList.add(qLIStep);
                }
                if (counter == (steppedList.size() - 1) && headLine.Term__c > qLIStep.Rent_Step_To__c) {
                    allStepsList.add(new SBQQ__QuoteLine__c(Start_Term__c = steppedList[counter].Rent_Step_To__c, Rent_Step_To__c = headLine.Term__c + 1,
                            Monthly_Total__c = headLine.Monthly_Average_Without_Discount__c));
                }
                counter += 1;
            }
        }
//        for (SBQQ__QuoteLine__c q: allStepsList) {
//            System.debug('---' + q);
//        }
        return allStepsList;

    }

    public static Map<String, List<SBQQ__QuoteLine__c>> obtainMapProducts(List<SBQQ__QuoteLine__c> lineItems) {
        Map<String, List<SBQQ__QuoteLine__c>> mapProducts = new Map<String, List<SBQQ__QuoteLine__c>>();
        for (SBQQ__QuoteLine__c lineItem : lineItems) {
            String code = lineItem.SBQQ__ProductCode__c;
            if (!mapProducts.containsKey(code)) {
                mapProducts.put(code, new List<SBQQ__QuoteLine__c>());
            }
            mapProducts.get(code).add(lineItem);
        }
        return mapProducts;
    }

    public static String obtainCodes(Map<String, List<SBQQ__QuoteLine__c>> products) {
        String codes = ' ';
        for (String code : products.keySet()) {
            codes += code + ', ';
        }
        return codes;
    }

    public static String getSuiteType(List<SBQQ__QuoteLine__c> lineItems) {

        for (SBQQ__QuoteLine__c qLI : lineItems) {
            if (isSuiteBundle(qLI)) {
                return qLI.SBQQ__ProductCode__c;
            }

        }

        return null;
    }

    public static List<SBQQ__QuoteLine__c> getQuoteLines(String quoteId) {
        return [
                SELECT Id, Name, SBQQ__Product__r.Name,

                        Suite_inventory__r.Name, Suite_inventory__r.Rent_per_sq_ft__c,
                        Suite_inventory__r.Workstations__c,Suite_inventory__r.Size_sq_ft__c,
                        Suite_inventory__r.Service_Charge_Total__c, Suite_inventory__r.Service_Charge_per_sq_ft__c,
                        Suite_inventory__r.Insurance_Charge_per_sq_ft__c, Suite_inventory__r.Insurance_Charge_Total__c,
                        Suite_Inventory__r.Service_Charge_per_sq_ft_Annual__c, Suite_Inventory__r.Insurance_Charge_per_sq_ft_Annual__c,
                        Suite_Inventory__r.Estate_Charge_Total__c,Suite_Inventory__r.Estate_Charge_per_sq_ft__c,
                        Inventory__r.Cost_per_space__c, Inventory__r.Name,Inventory__r.Rent_per_sq_ft__c,Inventory__r.Size_sq_ft__c,
                        Inventory__r.Workstations__c,Inventory__c,Inventory__r.Estate_Charge_per_sq_ft__c,Inventory__r.Rent_Total__c,
                        Inventory__r.Property__r.Address__c, Inventory__r.Estate_Charge_per_sq_ft_Annual__c,

                        Minimum_Notice__c, Maximum_Notice__c, Discount_Term_Certain__c,Rent_Review_Timing__c,
                        Number_of_Hours__c,
                        Break_Date__c, Break_Penalty__c, Floor_Number__c, Rent_per_Sq_Ft_annual__c,Square_Footage__c,
                        Rent_Review_Anniversary__c, Rent_Review_Type__c, When_to_Start_the_Term__c, Lease_Start_Date__c,
                        Indicative_Start_Date__c,Term__c, Updated_Price_per_sq_ft__c, Discount_Full_Term__c, Legal_Fees_Cap__c,
                        Number_of_Rental_Months__c, Total__c, Works_Prior_to_Lease_Start__c, Suppliers_Contribution__c,
                        Net_Subtotal__c, Project_Management_Fee__c, Discount_Percent__c, Percentage_Upfront__c, Status__c,
                        Guarantor_Name__c, Type_of_Guarantor__c, Net_Total__c,Start_Date__c, End_Date__c,
                        Registered_Address__c,Annual_Average__c,Annual_Cost__c,Discount_Total__c,Deposit_Already_Held__c,
                        Monthly_Average_Without_Discount__c,Rent_Per_Workstation__c,Start_Term__c, SBQQ__Quantity__c,
                        Revised_Price_Cost_Per_Handset_PCM__c, Licence_Start_Date__c, SBQQ__RequiredBy__c,
                        Discount_Amount__c,Shared_Meter__c,Maintained_By__c,Cap_Amount__c,Cap_Expiry_Month__c,
                        Serviced_Internet_Bandwidth__c, Monthly_Cost__c,Monthly_Average__c,Required_Months_before_Notice__c,
                        Rent_Step_To__c, Monthly_Total__c, SBQQ__ProductCode__c, SBQQ__ProductFamily__c, SBQQ__BillingFrequency__c,SBQQ__BillingType__c,
                        SBQQ__ListPrice__c,Additional_Services_Total__c,SBQQ__NetTotal__c,Updated_Monthly_Average__c,Updated_Rent_Per_Workstation__c,
                        Additional_Seats__c,SBQQ__ProductOption__r.SBQQ__Feature__r.name,Annual_Price_per_Sq_Ft__c,
                        Date_Balance_Due__c,Capital_Allowances__c,Fixed__c,Date__c,Payable_by_customer__c,Works_undertaken__c,
                        Conducted_By__c,Rent_review_date__c, SBQQ__Bundle__c, New_Monthly_Average__c

                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
        ];
    }

    public static SBQQ__Quote__c getQuoteDetails(String quoteId) {
        try {
            return [
                    SELECT ID, Name, Property__r.Name,Property__r.Company_Logo__c,Property__r.Company_Name__c,
                            Property__r.Company_Address__c,Property__r.Portfolio__c, Property__r.Street__c, Property__r.City__c,
                            Property__r.Post_Code__c,Property__r.Address__c, BW_Signature__r.Name, Property__r.Quote_Header_Link__c,
                            Property__r.Property_Image_Link_1__c, Property__r.Property_Image_Link_2__c,Property__r.Property_Image_Link_3__c,
                            Property__r.Property_USPs__c,Property__r.Company_Website__c,Property__r.Serviced_Package_Details__c,
                            Property__r.Serviced_Space_Package__c,Estimated_Business_Rate_Per_Annum__c,
                            SBQQ__Account__r.Registered_Name__c,SBQQ__Account__r.Name,SBQQ__Account__r.ShippingAddress,
                            SBQQ__Account__r.ShippingCity,SBQQ__Account__r.ShippingPostalCode, SBQQ__Account__r.ShippingCountry,
                            SBQQ__Account__r.ShippingStreet, SBQQ__Account__r.Company_Registration_Number__c,

                            SBQQ__Opportunity2__r.Type,
                            SBQQ__Type__c, SBQQ__StartDate__c, Secondary_Signature__c,
                            Surrender_Premium__c, Legacy_contract__r.Property__r.Name, Surrender_deed_due_date__c, Surrender_deed_weeks__c

                    FROM SBQQ__Quote__c
                    WHERE id = :quoteId
                    LIMIT 1
            ];
        } catch (Exception exc) {
            String errorMsg = 'There was an error getting Quote. Exception Cause = ' +
                    exc.getCause() + ', Exception Message = ' + exc.getMessage();
            System.debug('=====> ' + errorMsg);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
        }

        return null;
    }

    public static Boolean isSuiteBundle(SBQQ__QuoteLine__c quoteLine) {
        return quoteLine.SBQQ__Bundle__c && ProductService.PRODUCT_FAMILY_SUITE.equalsIgnoreCase(quoteLine.SBQQ__ProductFamily__c);
    }
}