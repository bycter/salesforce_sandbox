public with sharing class OpportunityTriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        assignRT((List<Opportunity>) Trigger.new);
        mapLeadFields((List<Opportunity>) Trigger.new);
        assignPriceBookOnOpportunity((List<Opportunity>) Trigger.new);
        createTaskForCoordinator(Trigger.new, null);
    }

    protected override void beforeUpdate() {
        assignPriceBookOnOpportunity((List<Opportunity>) Trigger.new);
        changeStatusOnQuote((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
        recalculateOpportunityStatusIfNeeded(Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
        createTaskForCoordinator(Trigger.new, Trigger.oldMap);
    }

    protected override void afterUpdate() {
        pushCompletionNotification((List<Opportunity>) Trigger.new, (Map<Id, Opportunity>) Trigger.oldMap);
    }

    private void assignRT(List<Opportunity> opportunities) {
        for (Opportunity opportunity : opportunities) {
            RecordTypeInfo oppRecordTypeInfo = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(opportunity.Opportunity_Record_type_Conversion__c);
            if (oppRecordTypeInfo != null) {
                opportunity.RecordTypeId = oppRecordTypeInfo.getRecordTypeId();
            }
        }
    }

    private void mapLeadFields(List<Opportunity> opportunities) {
        for (Opportunity opportunity : opportunities) {
            opportunity.Use__c = opportunity.Use__c == null ? opportunity.Use_for_conversion__c : opportunity.Use__c;
            opportunity.Product__c = opportunity.Product__c == null ? opportunity.Product_for_conversion__c : opportunity.Product__c;
        }
    }

    private void createTaskForCoordinator(List<sObject> opportunities, Map<Id, sObject> oldOpportunitiesMap) {
        List<sObject> virtualOpportunoities = SObjectUtils.filterRecordsByRecordType(opportunities, new Set<Id>{
                OpportunityService.VIRTUAL_RECORD_TYPE_ID
        });
        List<sObject> modifiedVirtuals = SObjectUtils.getModifiedObjects(new List<String>{
                'StageName'
        }, virtualOpportunoities, oldOpportunitiesMap);
        if (!modifiedVirtuals.isEmpty()) {
            OpportunityService.createTaskForCoordinator(modifiedVirtuals);
        }
    }

    private void assignPriceBookOnOpportunity(List<Opportunity> opportunities) {
        Map<String, Pricebook2> pricebooks = getPriceBooks();

        for (Opportunity opp : opportunities) {
            Pricebook2 pricebook = pricebooks.get(
                OpportunityService.getRecrodTypes().get(opp.RecordTypeId).DeveloperName
            );
            if (pricebook != null) {
                opp.Pricebook2Id = pricebook.Id;
            }
        }
    }

    private void changeStatusOnQuote(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        Set<Id> quoteIds = new Set<Id>();
        List<Case> cases = new List<Case>();
        List<SBQQ__Quote__c> quotesUpdate = new List<SBQQ__Quote__c>();

        for (Opportunity opp : newOpportunities) {
            if (opp.StageName != oldOpportunities.get(opp.Id).StageName && opp.StageName == Constants.STAGENAME_CLOSED_LOST //TODO: move Stages to one place
                    && opp.Closed_Lost_Reason__c != null) {
                oppMap.put(opp.Id, opp);
            }
        }
        //Define all Quotes related with Opportunity
        List<SBQQ__Quote__c> quotes = [
                SELECT Id, SBQQ__Opportunity2__c, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c IN :oppMap.keySet()
        ];
        if (!quotes.isEmpty()) {
            for (SBQQ__Quote__c quote : quotes) {
                quoteIds.add(quote.id);
            }
        }
        //Define all Cases related with Quotes
        if (!quoteIds.isEmpty()) {
            cases = [
                    SELECT Id, Status, RecordType.DeveloperName, Quote__c
                    FROM Case
                    WHERE Quote__c IN :quoteIds
                    AND Status != :Constants.STATUS_CLOSED_LOST
                    AND RecordType.DeveloperName IN ('Lease_Transaction', 'Outsourced_Lease_Transaction')
            ];
            //On Quotes, change Status to Obsolete if all related Cases are 'Closed Lost'
            if (!cases.isEmpty()) {
                for (Opportunity opp : oppMap.values()) {
                    opp.addError('Close Lease Transaction Case first!');
                }
            } else {
                for (SBQQ__Quote__c quote : quotes) {
                    quote.SBQQ__Status__c = Constants.STATUS_OBSOLETE;
                    quotesUpdate.add(quote);
                }
            }
            if (!quotesUpdate.isEmpty()) {
                update quotesUpdate;
            }
        }
    }

    private Map<String, Pricebook2> getPriceBooks() {
        List<Pricebook2> priceBooks = [
                SELECT Id, RecordType.DeveloperName
                FROM Pricebook2
                WHERE RecordType.Id != null AND IsActive = TRUE
        ];
        Map<String, Pricebook2> priceBooksMap = new Map<String, Pricebook2>();
        for (Pricebook2 pricebook : priceBooks) {
            priceBooksMap.put(pricebook.RecordType.DeveloperName, pricebook);
        }
        return priceBooksMap;
    }

    private void recalculateOpportunityStatusIfNeeded(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldMap) {
        Set<String> fieldsUsedInOppStatusCalculation = new Set<String>{
                'Viewing_Count__c', 'Event_Count__c', 'HOTs_Sent__c', 'HOTs_Signed__c', 'LA_Sent__c', 'LA_Signed__c', 'LT_Case_Completed__c',
                'Contracts_Exchanged__c', 'Contract_Activated__c', 'Compliance_Check_Complete__c', 'Virtual_Compliance_Approval_Complete__c',
                'Briefing_Statement__c', 'Deposit_Paid__c', 'Closed_Lost_Reason__c', 'Closed_Lost_Comments__c', 'Force_Status_Recalculation__c'
        };
        List<Opportunity> oppsForStatusCalculation = new List<Opportunity>();
        for (Opportunity theOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldMap.get(theOpportunity.Id);
            for (String fieldName : fieldsUsedInOppStatusCalculation) {
                if (theOpportunity.get(fieldName) != oldOpportunity.get(fieldName)) {
                    oppsForStatusCalculation.add(theOpportunity);
                }
            }
            theOpportunity.Force_Status_Recalculation__c = false;
        }
        OpportunityService.calculateOpportunitiesStatuses(oppsForStatusCalculation);
    }

    private void pushCompletionNotification(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        List<Opportunity> oppWithCompletionStatus = new List<Opportunity>();

        for (Opportunity theOpportunity : newOpportunities) {
            Opportunity oldOpportunity = oldOpportunitiesMap.get(theOpportunity.Id);
            if (oldOpportunity.StageName != theOpportunity.StageName
                    && (theOpportunity.StageName == OpportunityService.STATUS_COMPLETED //TODO: move Stages to one place
                    || theOpportunity.StageName == OpportunityService.STATUS_EXCHANGED
                    || theOpportunity.StageName == OpportunityService.STATUS_INSTRUCTED)
                    ) {
                oppWithCompletionStatus.add(theOpportunity);
            }
        }
        if (oppWithCompletionStatus.size() > 0) {
            pushChatterPostForCompletedOpportunity([SELECT Id, Account.Name, StageName, Completion_Notification__c, Owner.Name,
                    Type, LeadSource
                FROM Opportunity WHERE ID IN :oppWithCompletionStatus]);
        }

    }

    private void pushChatterPostForCompletedOpportunity(List<Opportunity> completedOpportunities) {
        List<String> feedItemsBodies = new List<String>();
        Map<String, SBQQ__Quote__c> primaryQuotesByOpportunities = OpportunityService.getPrimaryQuotesByOpportunities(completedOpportunities);

        for (Opportunity theOpportunity : completedOpportunities) {
            String opportunityUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theOpportunity.Id;
            String quoteUrl = '';
            if (primaryQuotesByOpportunities.containsKey(theOpportunity.Id)) {
                quoteUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + primaryQuotesByOpportunities.get(theOpportunity.Id).Id ;
            }
            feedItemsBodies.add('<p> A deal has hit a milestone. ' +
                    +theOpportunity.Account.Name + '. The status it has moved to ' + theOpportunity.StageName + '.</p> <p> Opportunity: ' +
                    + opportunityUrl + '</p> <p> Quote: ' + quoteUrl + '</p>' +
                    +'<p> Property: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Property_Name__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Property_Name__c : '') + '</p>' +
                    +'<p> Inventory: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Inventory__r.Name != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Inventory__r.Name : '') + '</p>' +
                    +'<p> Opportunity Owner: ' + theOpportunity.Owner.Name + '</p>' +
                    +'<p> Lead Source: ' + theOpportunity.LeadSource + '</p>' +
                    +'<p> Net Fill: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Net_Fill_Sq_ft__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Net_Fill_Sq_ft__c : 0) + '</p>' +
                    +'<p> Total Deal Size: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Total_deal_size_Sq_ft__c != null ?
                                primaryQuotesByOpportunities.get(theOpportunity.Id).Total_deal_size_Sq_ft__c : 0) + '</p>' +
                    +'<p> Deal Type: ' + (theOpportunity.Type != NULL ? theOpportunity.Type : '') + '</p>' +
                    +'<p> Term: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Term__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Term__c : 0)+ '</p>'
                    +'<p> Term Certain: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Term_certain__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Term_certain__c : 0)+ '</p>' +
                    +'<p> Rent per sq ft: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Rent_per_Sq_Ft_annual__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Rent_per_Sq_Ft_annual__c : 0) + '</p>' +
                    +'<p> Discount Term Certain: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Discount_Term_Certain__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Discount_Term_Certain__c : 0)+ '</p>' +
                    +'<p> Total parking spaces: ' + (primaryQuotesByOpportunities.get(theOpportunity.Id).Total_Parking_Spaces__c != null ?
                        primaryQuotesByOpportunities.get(theOpportunity.Id).Total_Parking_Spaces__c : 0)+ '</p>' +
                    +'<p> Completion Notification: ' + (theOpportunity.Completion_Notification__c != NULL ? theOpportunity.Completion_Notification__c : '') + '</p>'
                );

        }

        ChatterService.pushFeedItems(feedItemsBodies, ChatterService.findChatterGroupByName(Constants.OPPORTUNITY_NOTIFICATION_GROUP_NAME));
    }
}