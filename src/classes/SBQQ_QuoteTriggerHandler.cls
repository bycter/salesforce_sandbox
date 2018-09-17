public class SBQQ_QuoteTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        setPricebookFromOpportunity(Trigger.new); //TODO: remove it after CPQ fix their issue https://success.salesforce.com/issues_view?id=a1p3A000000EHNCQA4
        markQuoteAsPrimary(Trigger.new);
        prepopulateBWCountersignUser(Trigger.new);
        SetQuoteRecordTypeSource((List<SBQQ__Quote__c>) Trigger.new);
    }

    public override void beforeUpdate() {
        SBQQ_QuoteService.setCarParkingInfo(Trigger.new);
        //Calculates summary fields as per BWSFDC-1059
        SBQQ_QuoteService.setDealSizeAndNetFillInfo(Trigger.new);
        SBQQ_QuoteService.cleanup();
        //Locks an quote if it's in Draft status. Unlocks an quote if it isn't in Draft status.
        updateQuotesLock(Trigger.new);
        createContractWithSubscriptions(Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
        setCallExpiryFullTermField(Trigger.new, Trigger.oldMap);
        SetQuoteRecordTypeSource((List<SBQQ__Quote__c>) Trigger.new);
    }

    public override void afterUpdate() {
        List<SBQQ__Quote__c> acceptedQuotes = findAcceptedQuotes((List<SBQQ__Quote__c>) Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
        handleAcceptedQuotes(acceptedQuotes);
        //If an quote is moved in Draft or Obsolete status, all its related documents should be withdrawn from DocuSign
        withdrawRelatedDocuments(Trigger.new);
        //Pay by BACs option should be approved once the task completed
        createPayByBacsTasks((List<SBQQ__Quote__c>) Trigger.new);
        approveDocuments((List<SBQQ__Quote__c>) Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
        deleteNonapprovedDocuments((List<SBQQ__Quote__c>) Trigger.new, (Map<Id, SBQQ__Quote__c>) Trigger.oldMap);
        SBQQ_QuoteService.cleanup();
        ContactService.cleanup();
        withdrawFromApprovalProcess((List<SBQQ__Quote__c>) Trigger.new);
    }

    private void SetQuoteRecordTypeSource(List<SBQQ__Quote__c> quotes){
        for (SBQQ__Quote__c quote : quotes){
            if (quote.RecordTypeId != null) {
                RecordType recordType = SBQQ_QuoteService.getRecrodTypes().get(quote.RecordTypeId);

                if (recordType.DeveloperName.contains(SBQQ_QuoteConstants.CONVENTIONAL_RECORD_TYPE)) {
                    quote.Quote_Record_Type_Source__c = SBQQ_QuoteConstants.CONVENTIONAL_RECORD_TYPE;
                }

                if (recordType.DeveloperName.contains(SBQQ_QuoteConstants.SERVICED_RECORD_TYPE)) {
                    quote.Quote_Record_Type_Source__c = SBQQ_QuoteConstants.SERVICED_RECORD_TYPE;
                }

                if (recordType.DeveloperName.contains(SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE)) {
                    quote.Quote_Record_Type_Source__c = SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE;
                }

                if (recordType.DeveloperName.contains(SBQQ_QuoteConstants.MEETING_ROOMS_RECORD_TYPE)) {
                    quote.Quote_Record_Type_Source__c = SBQQ_QuoteConstants.MEETING_ROOMS_RECORD_TYPE;
                }
            }

        }
    }

    private Boolean isOfflineDocumentApprovalProcess(SBQQ__Quote__c oldQuote) {
        return oldQuote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_AWAITING_APPROVAL_OFFLINE_EDIT || oldQuote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_PENDING_APPROVAL_OFFLINE_EDIT;
    }

    private void approveDocuments(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldQuotes) {
        List<Id> quotesIds = new List<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            if (quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_APPROVED && isOfflineDocumentApprovalProcess(oldQuotes.get(quote.Id))) {
                quotesIds.add(quote.Id);
            }
        }
        List<SBQQ__RelatedContent__c> additionaDocuments = [SELECT Id, IsDocumentApproved__c FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c IN :quotesIds];
        for (SBQQ__RelatedContent__c document : additionaDocuments) {
            document.IsDocumentApproved__c = true;
        }
        update additionaDocuments;
    }

    private void deleteNonApprovedDocuments(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldQuotes) {
        List<Id> quotesIds = new List<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            if (isOfflineDocumentApprovalProcess(oldQuotes.get(quote.Id)) && (quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_DRAFT || quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_REJECTED)) {
                quotesIds.add(quote.Id);
            }
        }
        delete [SELECT Id, IsDocumentApproved__c FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c IN :quotesIds AND (IsDocumentApproved__c = false AND Manual_Upload__c = true)];
    }


    private void handleAcceptedQuotes(List<SBQQ__Quote__c> acceptedQuotes) {
        Map<Id, SBQQ__Quote__c> acceptedQuotesMap = new Map<Id, SBQQ__Quote__c>(acceptedQuotes);
        // Get Opportunities
        Map<Id, Opportunity> opportunities = SBQQ_QuoteService.getOpportunitiesFromQuotes(acceptedQuotes);
        Set<Id> accountIds = SObjectUtils.getIdSetFromObjects(opportunities.values(), 'AccountId');
        // Get In Life Property Contacts
        Map<Id, List<Contact>> inLifePropertyContacts = ContactService.getInLifePropertyContactsMap(accountIds);
        // Get Legal Contacts
        Map<Id, List<Contact>> legalContacts = ContactService.getLegalContactsMap(accountIds);
        // Get Project Management Contacts
        Map<Id, List<Contact>> projectManagementContacts = ContactService.getProjectManagementContactsMap(accountIds);
        // Select Properties from Quotes
        Map<Id, Property__c> propertiesById = SBQQ_QuoteService.getPropertiesFromQuotes(acceptedQuotes);
        // Select QuoteLines lists by Quotes
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = SBQQ_QuoteService.getQuoteLinesMap(acceptedQuotes);

        Map<Id, Integer> quoteLinesInventorySuite = SBQQ_QuoteService.getNumberOfInventorySuite(quoteLinesByQuoteId);
        Set<Id> soldInventoryIds = SBQQ_QuoteService.findSoldInventoryIdsFromQuoteLines(quoteLinesByQuoteId);
        updateInventoryStatus(soldInventoryIds);
        //BWFSDC-442
        chatterPostsToAssetManagementAboutSoldProposedSuites(soldInventoryIds);

        //find quote line items to remove inventory and notify quote owner
        List<SBQQ__QuoteLine__c> qlToUpdate = findQuoteLinesToUpdate(soldInventoryIds);
        removeInventories(qlToUpdate);

        //START - Create Cases
        List<SBQQ__Quote__c> acceptedConventionalQuotes = new List<SBQQ__Quote__c>();
        List<SBQQ__Quote__c> acceptedServicedSpaceQuotes = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : acceptedQuotes) {
            //Onboarding cases shouldn't be generated if Quote Type = Renewal (BWSFDC-1648)
            if (opportunities.containsKey(quote.SBQQ__Opportunity2__c) && quote.SBQQ__Type__c != SBQQ_QuoteConstants.TYPE_RENEWAL) {
                if (quote.RecordTypeId == RecordTypeHelper.getSbqqQuoteRtIdByDeveloperName(SBQQ_QuoteConstants.CONVENTIONAL_LOCKED_RECORD_TYPE)) {
                    if (quoteLinesInventorySuite.containsKey(quote.Id) && quoteLinesInventorySuite.get(quote.Id) > 0) {
                        acceptedConventionalQuotes.add(quote);
                    }
                } else if (quote.RecordTypeId == RecordTypeHelper.getSbqqQuoteRtIdByDeveloperName(SBQQ_QuoteConstants.SERVICED_LOCKED_RECORD_TYPE)) {
                    if (quoteLinesInventorySuite.containsKey(quote.Id) && quoteLinesInventorySuite.get(quote.Id) > 0) {
                        acceptedServicedSpaceQuotes.add(quote);
                    }
                }
            }
        }

        List<Case> leaseTransactionCases = NewCaseFromQuote.createLeaseTransactionCases(getSuiteLeaseTransactionQuotes(acceptedQuotes), opportunities, legalContacts);
        List<Case> fitOutCases = [
                SELECT Id, RecordType.DeveloperName, Quote__c
                FROM Case
                WHERE RecordType.DeveloperName IN (
                        :CaseService.DESIGN_RECORD_TYPE,
                        :CaseService.FIT_OUT_DESIGN_RECORD_TYPE,
                        :CaseService.BUILDING_CONSTRUCTION_CASE_RECORD_TYPE
                )
                AND Quote__c IN :acceptedQuotesMap.keySet()
        ];
        populateFitOutCasesInLeaseTransactionCases(leaseTransactionCases, fitOutCases);

        List<Case> casesForInsert = new List<Case>();
        casesForInsert.addAll(leaseTransactionCases);
        if (!casesForInsert.isEmpty()) {
            insert casesForInsert;
        }

        Map<Id, Id> quoteIdToCaseId = new Map<Id, Id>();
        for (Case theCase : leaseTransactionCases) {
            quoteIdToCaseId.put(theCase.Quote__c, theCase.Id);
        }

        List<Case> conventionalOnboardingCases = NewCaseFromQuote.createConventionalOnboardingCases(acceptedConventionalQuotes, opportunities, inLifePropertyContacts, quoteLinesByQuoteId, propertiesById);
        List<Case> servicedSpaceOnboardingCase = NewCaseFromQuote.createServicedSpaceOnboardingCase(acceptedServicedSpaceQuotes, opportunities, inLifePropertyContacts, quoteLinesByQuoteId, propertiesById);

        casesForInsert = new List<Case>();
        casesForInsert.addAll(conventionalOnboardingCases);
        casesForInsert.addAll(servicedSpaceOnboardingCase);
        if (!casesForInsert.isEmpty()) {
            for (Case theCase : casesForInsert) {
                if (quoteIdToCaseId.containsKey(theCase.Quote__c)) {
                    theCase.ParentId = quoteIdToCaseId.get(theCase.Quote__c);
                }
            }
            insert casesForInsert;
        }

        List<Case> fitOutCasesForUpdate = new List<Case>();
        for (Case theCase : fitOutCases) {
            Boolean toBeUpdated = false;
            if (theCase.Quote__c != null) {

                if (theCase.RecordType.DeveloperName == CaseService.FIT_OUT_DESIGN_RECORD_TYPE) {
                    theCase.RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.BUILDING_CONSTRUCTION_CASE_RECORD_TYPE);
                    theCase.OwnerId = QueueHelper.getRtIdByDeveloperName(QueueHelper.B_C_QUEUE);
                    theCase.Status = CaseService.STATUS_CUSTOMER_CONFIRMED;
                    toBeUpdated = true;
                }

                if (quoteIdToCaseId.containsKey(theCase.Quote__c)) {
                    theCase.ParentId = quoteIdToCaseId.get(theCase.Quote__c);
                    toBeUpdated = true;
                }

                SBQQ__Quote__c quote = acceptedQuotesMap.get(theCase.Quote__c);
                if (opportunities.containsKey(quote.SBQQ__Opportunity2__c)) {
                    Id accountId = opportunities.get(quote.SBQQ__Opportunity2__c).AccountId;
                    if (accountId != null && projectManagementContacts.containsKey(accountId)) {

                        Contact pmContact = !projectManagementContacts.get(accountId).isEmpty()
                                ? projectManagementContacts.get(accountId).get(0)
                                : null;
                        theCase.ContactId = pmContact != null ? pmContact.Id : theCase.ContactId;
                        toBeUpdated = true;
                    }
                }
            }
            if (toBeUpdated) {
                fitOutCasesForUpdate.add(theCase);
            }
        }
        if (!fitOutCasesForUpdate.isEmpty()) {
            update fitOutCasesForUpdate;
        }
        //END - Create Cases

        EmailHelper.sendEmailsToQuoteOwners(acceptedQuotesMap.keySet(), EmailHelper.QUOTE_ACCEPTED_EMAIL_TEMPLATE);
        notifyPropertyManagerWhenFitOutIsRequired(acceptedQuotes, quoteLinesByQuoteId, propertiesById);
    }

    private static void notifyPropertyManagerWhenFitOutIsRequired(List<SBQQ__Quote__c> acceptedQuotes, Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId, Map<Id, Property__c> propertiesById) {
        Set<String> fitOutProducts = new Set<String>{
                ProductService.PRODUCT_CODE_REFURBISHMENT_CUSTOMER,
                ProductService.PRODUCT_CODE_REFURBISHMENT_SUPPLIER,
                ProductService.PRODUCT_CODE_FIT_OUT_CUSTOMER,
                ProductService.PRODUCT_CODE_FIT_OUT_SUPPLIER
        };
        Map<Id, Id> entityIdByUserId = new Map<Id, Id>();
        for (SBQQ__Quote__c quote : acceptedQuotes) {
            if (quote.Record_Type__c == SBQQ_QuoteConstants.CONVENTIONAL_RECORD_TYPE && propertiesById.containsKey(quote.Property__c)) {
                for (SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteId.get(quote.Id)) {
                    if (fitOutProducts.contains(quoteLine.SBQQ__Product__r.ProductCode)) {
                        entityIdByUserId.put(quote.Id, propertiesById.get(quote.Property__c).Property_Manager__c);
                        break;
                    }
                }
            }
        }
        EmailHelper.sendEmailToUsers(entityIdByUserId, EmailHelper.FIT_OUT_NOTIFICATION_TO_PM_EMAIL_TEMPLATE);
    }

    private List<SBQQ__Quote__c> getSuiteLeaseTransactionQuotes(List<SBQQ__Quote__c> acceptedQuotes) {
        Set<String> suiteProducts = new Set<String>{
                ProductService.PRODUCT_CODE_LAB_SPACE,
                ProductService.PRODUCT_CODE_OFFICE_RENT,
                ProductService.PRODUCT_CODE_RETAIL_RENT,
                ProductService.PRODUCT_CODE_STORAGE
        };
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = SBQQ_QuoteService.getQuoteLinesMap(acceptedQuotes);
        List<SBQQ__Quote__c> suiteQuotes = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : acceptedQuotes) {
            if (quote.Record_Type__c == SBQQ_QuoteConstants.CONVENTIONAL_RECORD_TYPE) {
                for (SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteId.get(quote.Id)) {
                    if (suiteProducts.contains(quoteLine.SBQQ__ProductCode__c)) {
                        suiteQuotes.add(quote);
                        break;
                    }
                }
            }
        }
        return suiteQuotes;
    }

    //BWSFDC-500 Contract object generation
    private void createContractWithSubscriptions(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldQuotes) {
        //filter accepted quotes without a contract
        Map<Id, SBQQ__Quote__c> acceptedQuotesMap = new Map<Id, SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : quotes) {
            if (quote.SBQQ__Status__c != oldQuotes.get(quote.Id).SBQQ__Status__c && quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_ACCEPTED/*&& quote.Contract_Created__c == false*/) { //TODO: it's temporary, for FF test, remove after
                acceptedQuotesMap.put(quote.Id, quote);
                quote.Contract_Created__c = true;
            }
        }
        ContractFromQuoteCreator.createContractWithSubscriptions(acceptedQuotesMap);
    }

    private List<SBQQ__Quote__c> findAcceptedQuotes(List<SBQQ__Quote__c> quotes, Map<Id, SBQQ__Quote__c> oldQuotes) {
        List<SBQQ__Quote__c> acceptedQuotes = new List<SBQQ__Quote__c>();

        for (SBQQ__Quote__c quote : quotes) {
            if (quote.SBQQ__Status__c != oldQuotes.get(quote.Id).SBQQ__Status__c && quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_ACCEPTED) {
                acceptedQuotes.add(quote);
            }
        }

        return acceptedQuotes;
    }

    private List<SBQQ__QuoteLine__c> findQuoteLinesToUpdate(Set<Id> soldInventoryIds) {
        List<SBQQ__QuoteLine__c> output = new List<SBQQ__QuoteLine__c>();

        if (!soldInventoryIds.isEmpty()) {
            output = [
                    select Id, Inventory__c, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Account__c,
                            SBQQ__Quote__r.SBQQ__PrimaryContact__c, SBQQ__Quote__r.OwnerId
                    from SBQQ__QuoteLine__c
                    where Inventory__c in :soldInventoryIds
                    and SBQQ__Quote__r.SBQQ__Status__c != 'Accepted'
                    and SBQQ__Quote__r.SBQQ__Status__c != 'Expired'
                    and SBQQ__Quote__r.SBQQ__Status__c != 'Obsolete'
            ];
        }
        return output;
    }

    private List<SBQQ__QuoteLine__c> extractUnique(List<SBQQ__QuoteLine__c> qlToUpdate) {
        List<SBQQ__QuoteLine__c> result = new List<SBQQ__QuoteLine__c>();
        for (SBQQ__QuoteLine__c quoteLine : qlToUpdate) {
            if (isUniqueQuoteLine(quoteLine, result)) {
                result.add(quoteLine);
            }
        }
        return result;
    }

    private Boolean isUniqueQuoteLine(SBQQ__QuoteLine__c quoteLine, List<SBQQ__QuoteLine__c> curResult) {
        Boolean answer = true;
        for (SBQQ__QuoteLine__c ql : curResult) {
            if (ql.Inventory__c == quoteLine.Inventory__c && ql.SBQQ__Quote__c == quoteLine.SBQQ__Quote__c) {
                answer = false;
                break;
            }
        }
        return answer;
    }

    private void updateInventoryStatus(Set<Id> soldInventoryIds) {
        List<Inventory__c> inventories = new List<Inventory__c>();
        for (Id inventoryId : soldInventoryIds) {
            inventories.add(new Inventory__c(Id = inventoryId, Sales_Status__c = 'Not Available'));
        }
        update inventories;
    }

    private void chatterPostsToAssetManagementAboutSoldProposedSuites(Set<Id> soldInventoryIds) {
        if (!soldInventoryIds.isEmpty()) {
            List<String> feedItemsBodies = new List<String>();
            List<Inventory__c> inventories = [
                    select Id, Name, Property__r.Asset_Management_Head__c
                    from Inventory__c
                    where Id in :soldInventoryIds and RecordType.DeveloperName = 'Proposed_Suite'
            ];

            for (Inventory__c inventory : inventories) {
                String inventoryUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + inventory.Id ;
                feedItemsBodies.add('Proposed suite ' + inventory.Name + ' was sold. Actualize inventories! <p>&nbsp;</p>' + inventoryUrl);
            }

            ChatterService.pushFeedItems(feedItemsBodies, ChatterService.findChatterGroupByName(Constants.ASSET_MANAGEMENT_CHATTER_GROUP_NAME));
        }
    }

    private void removeInventories(List<SBQQ__QuoteLine__c> qlToUpdate) {
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__QuoteLine__c quoteLine : qlToUpdate) {
            quoteIds.add(quoteLine.SBQQ__Quote__c);
            quoteLine.Inventory__c = null;
            quoteLine.Suite_Inventory__c = null;
            quoteLine.Car_Parking_Inventory__c = null;
        }
        upsert qlToUpdate;
        EmailHelper.sendEmailsToQuoteOwners(quoteIds, EmailHelper.QUOTE_ACCEPTED_ON_SAME_INVENTORY_EMAIL_TEMPLATE);
        changeQuotesStatusToObsolete(quoteIds);
    }

    private void updateQuotesLock(List<SBQQ__Quote__c> quotes) {
        for (SBQQ__Quote__c quote : quotes) {
            if (quote.RecordTypeId != null) {
                if (quote.SBQQ__Status__c != SBQQ_QuoteConstants.STATUS_DRAFT) {
                    lockQuote(quote);
                } else {
                    unlockQuote(quote);
                }
            }
        }
    }

    private void lockQuote(SBQQ__Quote__c quote) {
        RecordType recordType = SBQQ_QuoteService.getRecrodTypes().get(quote.RecordTypeId);
        RecordType recordTypeToLock = SBQQ_QuoteService.getRecordTypeByDeveloperName(recordType.DeveloperName + '_Locked');
        if (recordTypeToLock != null) {
            quote.RecordTypeId = recordTypeToLock.Id;
        }
    }

    private void unlockQuote(SBQQ__Quote__c quote) {
        RecordType recordType = SBQQ_QuoteService.getRecrodTypes().get(quote.RecordTypeId);
        RecordType recordTypeToUnlock = SBQQ_QuoteService.getRecordTypeByDeveloperName(recordType.DeveloperName.removeEnd('_Locked'));
        if (recordTypeToUnlock != null) {
            quote.RecordTypeId = recordTypeToUnlock.Id;
        }
    }

    private void withdrawRelatedDocuments(List<SBQQ__Quote__c> quotes) {
        Set<Id> quotesIdsInDraftOrObsolete = new Set<Id>();
        for (SBQQ__Quote__c quote : quotes) {
            if (quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_DRAFT || quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_OBSOLETE) {
                quotesIdsInDraftOrObsolete.add(quote.Id);
            }
        }

        if (!quotesIdsInDraftOrObsolete.isEmpty()) {
            //Limit the query of 100 rows due to Execution Governors and Limits (Please have a look at Callout Limits and Limitations)
            List<SBQQ__QuoteDocument__c> documents = [
                    SELECT Id, Docusign_Envelope_Id__c
                    FROM SBQQ__QuoteDocument__c
                    Where SBQQ__Quote__c IN :quotesIdsInDraftOrObsolete
                    AND Docusign_Envelope_Id__c != null
                    AND SBQQ__SignatureStatus__c NOT IN :SBQQ_QuoteConstants.NOT_WITH_DRAWING_SIGNATURE_STATUSES
                    LIMIT 100
            ];
            for (SBQQ__QuoteDocument__c document : documents) {
                if (!String.isBlank(document.Docusign_Envelope_Id__c)) {
                    DocuSignIntegrator.voidEnvelope(document.Docusign_Envelope_Id__c); //do callout
                }
            }
        }
    }

    private void setPricebookFromOpportunity(List<SBQQ__Quote__c> quotes) {
        Map<Id, Opportunity> opportunitiesMap = SBQQ_QuoteService.getOpportunitiesFromQuotes(quotes);
        for (SBQQ__Quote__c quote : quotes) {
            if (opportunitiesMap.get(quote.SBQQ__Opportunity2__c) != null) {
                quote.SBQQ__PriceBook__c = opportunitiesMap.get(quote.SBQQ__Opportunity2__c).Pricebook2Id;
                quote.SBQQ__PricebookId__c = quote.SBQQ__PriceBook__c;
            }
        }
    }

    private void createPayByBacsTasks(List<SBQQ__Quote__c> quotes) {
        List<Task> tasks = new List<Task>();
        for (SBQQ__Quote__c quote : quotes) {
            Boolean payBacsOldValue = ((SBQQ__Quote__c) (Trigger.oldMap.get(quote.Id))).Pay_by_BACs__c;
            if (quote.Pay_by_BACs__c && !payBacsOldValue && !quote.Pay_by_BACs_Approved__c && !quote.Pay_by_BACs_Rejected__c) {
                tasks.add(new Task(WhatId = quote.Id, Subject = 'Customer paying by BACS', System_Code__c = TaskService.PAY_BY_BACS_SYSTEM_CODE, OwnerId = quote.OwnerId, Status = 'Open'));
            }
        }
        //When the tasks completed, Pay_by_BACs_Approved__c field of the related quote will be checked.
        insert tasks;
    }

    public void setCallExpiryFullTermField(List<sObject> quotes, Map<Id, sObject> oldMap) {
        List<sObject> conventionalQuotes = SObjectUtils.filterRecordsByRecordType(quotes, SBQQ_QuoteService.getConventionalRecordTypeIds());
        List<sObject> acceptedQuotes = SObjectUtils.getModifiedObjects(new List<String>{
                'SBQQ__Status__c'
        }, conventionalQuotes, oldMap);
        if (!acceptedQuotes.isEmpty()) {
            SBQQ_QuoteService.setCallExpiryFullTermField(acceptedQuotes);
        }
    }

    public void changeQuotesStatusToObsolete(Set<Id> quotesIds) {
        List<SBQQ__Quote__c> quotesForUpdate = new List<SBQQ__Quote__c>();
        for (Id quoteId : quotesIds) {
            quotesForUpdate.add(new SBQQ__Quote__c(Id = quoteId, SBQQ__Status__c = 'Obsolete'));
        }
        update quotesForUpdate;
    }

    private void markQuoteAsPrimary(List<SBQQ__Quote__c> newQuoteList) {
        Set<String> oppIdSet = new Set<String>();
        //mark new Quote as Primary
        for (SBQQ__Quote__c quote : newQuoteList) {
            quote.SBQQ__Primary__c = true;
            oppIdSet.add(quote.SBQQ__Opportunity2__c);
        }
        //Select all old primary related quotes and mark as not primary
        List<SBQQ__Quote__c> oldQuoteList = [
                SELECT Id, SBQQ__Primary__c, SBQQ__Opportunity2__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c IN :oppIdSet AND SBQQ__Primary__c = true
        ];

        Set<Id> opportunitiesIds = new Set<Id>();
        for (SBQQ__Quote__c quote : oldQuoteList) {
            quote.SBQQ__Primary__c = false;
            opportunitiesIds.add(quote.SBQQ__Opportunity2__c);
        }

        update oldQuoteList;
        resetStatusOfRelatedOpportunities(opportunitiesIds);
    }

    private void resetStatusOfRelatedOpportunities(Set<Id> opportunitiesIds) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Id opportunityId : opportunitiesIds) {
            opportunities.add(new Opportunity(
                    Id = opportunityId,
                    HOTs_Sent__c = false,
                    HOTs_Signed__c = false,
                    LA_Sent__c = false,
                    LA_Signed__c = false,
                    Contracts_Exchanged__c = false,
                    Contract_Activated__c = false,
                    LT_Case_Completed__c = false
            ));
        }
        update opportunities;
    }

    private void populateFitOutCasesInLeaseTransactionCases(List<Case> leaseTransactionCases, List<Case> fitOutCases) {
        Map<Id, Case> leaseTransactionCasesByQuoteIds = getCasesByQuoteIds(leaseTransactionCases);
        for (Case fitOutCase : fitOutCases) {
            if (fitOutCase.Quote__c != null && leaseTransactionCasesByQuoteIds.containsKey(fitOutCase.Quote__c)) {
                leaseTransactionCasesByQuoteIds.get(fitOutCase.Quote__c).Fit_Out_Design_Case__c = fitOutCase.Id;
            }
        }
    }

    private Map<Id, Case> getCasesByQuoteIds(List<Case> cases) {
        Map<Id, Case> casesByQuoteIds = new Map<Id, Case>();
        for (Case theCase : cases) {
            casesByQuoteIds.put(theCase.Quote__c, theCase);
        }
        return casesByQuoteIds;
    }

    private void prepopulateBWCountersignUser(List<SBQQ__Quote__c> quotes) {
        Id countersignUserId = SBQQ_QuoteService.getBWCountersignUserId();
        Set<Id> requiredRecordTypesIds = new Set<Id>{
                RecordTypeHelper.getSbqqQuoteRtIdByDeveloperName(SBQQ_QuoteConstants.SERVICED_RECORD_TYPE),
                RecordTypeHelper.getSbqqQuoteRtIdByDeveloperName(SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE)
        };
        for (SBQQ__Quote__c theQuote : quotes) {
            if (requiredRecordTypesIds.contains(theQuote.RecordTypeId)) {
                theQuote.BW_Signature_User__c = countersignUserId;
            }
        }
    }

    private void withdrawFromApprovalProcess(List<SBQQ__Quote__c> quotes) {
        List<SBQQ__Quote__c> quotesForWithdrawing = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : quotes) {
            //If Quote Status is manually changed, the quote should be withdrawn from Approval Process
            if (quote.SBQQ__Status__c != SBQQ_QuoteConstants.STATUS_IN_REVIEW && quote.SBQQ__Status__c != SBQQ_QuoteConstants.STATUS_AWAITING_APPROVAL_OFFLINE_EDIT) {
                quotesForWithdrawing.add(quote);
            }
        }
        if (!Test.isRunningTest()) {
            SBQQ_QuoteService.withdrawFromApprovalProcess(quotesForWithdrawing);
        }
    }
}