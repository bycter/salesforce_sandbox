public with sharing class NewCaseFromQuote {

    private static Map<String, String> STORAGE_FIELDS_MAP = new Map<String, String>{
            'STR-1' => 'Storage_1_Inventory__c',
            'STR-2' => 'Storage_2_Inventory__c',
            'STR-3' => 'Storage_3_Inventory__c',
            'STR-4' => 'Storage_4_Inventory__c',
            'STR-5' => 'Storage_5_Inventory__c'
    };

    public static List<Case> createLeaseTransactionCases(List<SBQQ__Quote__c> quotes, Map<Id, Opportunity> opportunities, Map<Id, List<Contact>> legalContacts) {
        // Create Cases
        List<Case> casesForCreated = new List<Case>();
        for (SBQQ__Quote__c quote : quotes) {
            Opportunity theOpportunity = opportunities.get(quote.SBQQ__Opportunity2__c);

            //BWSFDC-1649
            if (!(theOpportunity.RecordTypeId == RecordTypeHelper.getOpportunityRtIdByDeveloperName(OpportunityService.SERVICED_RECORD_TYPE)
                    || theOpportunity.RecordTypeId == RecordTypeHelper.getOpportunityRtIdByDeveloperName(OpportunityService.VIRTUAL_RECORD_TYPE_NAME))) {

                Contact legalContact = legalContacts.containsKey(theOpportunity.AccountId)
                        && !legalContacts.get(theOpportunity.AccountId).isEmpty()
                        ? legalContacts.get(theOpportunity.AccountId).get(0)
                        : null;

                Case theCase = CaseService.generateDefaultLeaseTransactionCase(quote, theOpportunity);
                theCase.OwnerId = QueueHelper.getRtIdByDeveloperName(QueueHelper.LEASE_TRANSACTION_QUEUE);
                theCase.RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.LEASE_TRANSACTION_RECORD_TYPE);
                theCase.ContactId = legalContact != null ? legalContact.Id : null;
                casesForCreated.add(theCase);
            }
        }
        return casesForCreated;
    }

    public static List<Case> createConventionalOnboardingCases(List<SBQQ__Quote__c> quotes, Map<Id, Opportunity> opportunities, Map<Id, List<Contact>> inLifePropertyContacts, Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteIds, Map<Id, Property__c> propertiesByIds) {
        // STORAGE CODES
        Set<String> storageKeys = STORAGE_FIELDS_MAP.keySet();

        // Create Cases
        List<Case> casesForCreated = new List<Case>();
        for (SBQQ__Quote__c quote : quotes) {
            Opportunity theOpportunity = opportunities.get(quote.SBQQ__Opportunity2__c);
            Contact inLifeProperty = inLifePropertyContacts.containsKey(theOpportunity.AccountId)
                    && !inLifePropertyContacts.get(theOpportunity.AccountId).isEmpty()
                    ? inLifePropertyContacts.get(theOpportunity.AccountId).get(0)
                    : null;
            List<SBQQ__QuoteLine__c> quoteHeadLines = SBQQ_QuoteService.getHeadLinesFromQLI(quoteLinesByQuoteIds.get(quote.Id), quote.Id);

            Case theCase = CaseService.generateDefaultOnboardingCase(quote, quoteHeadLines, theOpportunity);
            theCase.OwnerId = propertiesByIds.get(quote.Property__c).Property_Manager__c;
            theCase.RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.CONVENTIONAL_ONBOARDING_RECORD_TYPE);
            theCase.ContactId = inLifeProperty != null ? inLifeProperty.Id : null;

            Set<String> carParkingInventoryNames = new Set<String>();
            for (SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteIds.get(quote.Id)) {
                String comparableId = quoteLine.Comparable_ID_for_Calculator__c;

                if (quoteLine.Suite_Inventory__c != NULL && quoteLine.SBQQ__RequiredBy__c == NULL) {
                    if (quoteLine.Bundle_Code__c == ProductService.PRODUCT_CODE_STORAGE
                            && String.isNotBlank(comparableId) && storageKeys.contains(comparableId)) {

                        theCase.put(STORAGE_FIELDS_MAP.get(comparableId), quoteLine.Suite_Inventory__c);
                    }

                    if (quoteLine.Bundle_Code__c != ProductService.PRODUCT_CODE_STORAGE
                            && quoteLine.Suite_Inventory__r.Product__c != null
                            && ProductService.isSuite(quoteLine.Suite_Inventory__r.Product__r)) {

                        theCase.Inventory__c = quoteLine.Suite_Inventory__c;
                    }
                }

                if (quoteLine.Car_Parking_Inventory__c != null) {
                    carParkingInventoryNames.add(quoteLine.Car_Parking_Inventory__r.Name);
                }
            }

            theCase.Car_Parkings__c = String.join((Iterable<String>) carParkingInventoryNames, ',');
            casesForCreated.add(theCase);
        }
        return casesForCreated;
    }

    public static List<Case> createServicedSpaceOnboardingCase(List<SBQQ__Quote__c> quotes, Map<Id, Opportunity> opportunities, Map<Id, List<Contact>> inLifePropertyContacts, Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteIds, Map<Id, Property__c> propertiesByIds) {
        // Create Cases
        List<Case> casesForCreated = new List<Case>();
        for (SBQQ__Quote__c quote : quotes) {

            Opportunity theOpportunity = opportunities.get(quote.SBQQ__Opportunity2__c);
            Contact inLifeProperty = inLifePropertyContacts.containsKey(theOpportunity.AccountId)
                    && !inLifePropertyContacts.get(theOpportunity.AccountId).isEmpty()
                    ? inLifePropertyContacts.get(theOpportunity.AccountId).get(0)
                    : null;
            List<SBQQ__QuoteLine__c> quoteHeadLines = SBQQ_QuoteService.getHeadLinesFromQLI(quoteLinesByQuoteIds.get(quote.Id), quote.Id);

            Case theCase = CaseService.generateDefaultOnboardingCase(quote, quoteHeadLines, theOpportunity);
            if (propertiesByIds.get(quote.Property__c).Serviced_Space_Coordinator__c != null) {
                theCase.OwnerId = propertiesByIds.get(quote.Property__c).Serviced_Space_Coordinator__c;
            } else {
                theCase.OwnerId = propertiesByIds.get(quote.Property__c).Property_Manager__c;
            }
            theCase.RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.SERVICED_SPACE_ONBOARDING_RECORD_TYPE);
            theCase.ContactId = inLifeProperty != null ? inLifeProperty.Id : null;

            Set<String> carParkingInventoryNames = new Set<String>();
            for (SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteIds.get(quote.Id)) {
                if (quoteLine.Suite_Inventory__c != NULL && quoteLine.SBQQ__RequiredBy__c == NULL &&
                        quoteLine.Bundle_Code__c != ProductService.PRODUCT_CODE_STORAGE &&
                        quoteLine.Suite_Inventory__r.Product__c != null &&
                        ProductService.isSuite(quoteLine.Suite_Inventory__r.Product__r)) {

                    theCase.Inventory__c = quoteLine.Suite_Inventory__c;
                }
                if (quoteLine.SBQQ__Product__c != null &&
                        quoteLine.SBQQ__Quantity__c != null &&
                        quoteLine.SBQQ__Product__r.Name.equalsIgnoreCase('Handsets')) {

                    theCase.Number_of_Phones__c = quoteLine.SBQQ__Quantity__c;
                }
                if (quoteLine.Car_Parking_Inventory__c != null) {
                    carParkingInventoryNames.add(quoteLine.Car_Parking_Inventory__r.Name);
                }
            }

            theCase.Car_Parkings__c = String.join((Iterable<String>) carParkingInventoryNames, ',');
            casesForCreated.add(theCase);
        }
        return casesForCreated;
    }

}