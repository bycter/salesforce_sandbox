public with sharing class CaseTriggerHandler extends TriggerHandler {

    public static final String LEASE_TRANSACTION_CASE_TEAM = 'Lease Transaction Case Team';

    protected override void beforeInsert() {
        addEntitlementToTheSLACase((List<Case>) Trigger.new);
        setAssignmentDateIfAssignedToTeamMember((List<Case>) Trigger.new);
        CaseService.setCaseInventory(Trigger.new);
        CaseService.setCasePreEmptionInventory(Trigger.new);
        CaseService.setOffLineEdits(Trigger.new);
        setContactInformation(Trigger.new);
    }

    protected override void beforeUpdate() {
        addEntitlementToTheSLACase((List<Case>) Trigger.new);
        setAssignmentDateIfAssignedToTeamMember((List<Case>) Trigger.new);
        checkThatCompleteCaseHasNotOpenTasks((List<Case>) Trigger.new);
        List<Case> fitOutCases = filterCasesByRecordType(Trigger.new, RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.FIT_OUT_DESIGN_RECORD_TYPE));
        updateOwnerEmail(fitOutCases, (Map<Id, Case>) Trigger.oldMap);
        CaseService.setOffLineEdits(Trigger.new);
        setContactInformation(Trigger.new);
    }

    protected override void afterUpdate() {
        changeStatusOnContract((List<Case>) Trigger.new, (Map<Id, Case>) Trigger.oldMap);
        List<Case> ltCases = getLeaseTransactionCases(Trigger.new);
        updateRelatedOpportunitiesForExchangedCases(getCasesWithNewStatus(ltCases, (Map<Id, Case>) Trigger.oldMap, 'Exchanged'));
        updateRelatedOpportunitiesForCompletedCases(getCasesWithNewStatus(ltCases, (Map<Id, Case>) Trigger.oldMap, 'Completed'));
        List<Case> fitOutCases = filterCasesByRecordType(Trigger.new, RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.FIT_OUT_DESIGN_RECORD_TYPE));
        updateNetOnQuoteLine(fitOutCases, (Map<Id, Case>) Trigger.oldMap);
    }

    /**
     *  System fields for populate email from SBQQ__SalesRep__c field on SBQQ__Quote__c object.
     *  Uses for email alert "FitOut cost is completed".
     */
    private void updateOwnerEmail(List<Case> fitOutCases, Map<Id, Case> oldCases) {
        Set<Id> quoteIds = SObjectUtils.getIdSetFromObjects(fitOutCases, 'Quote__c');
        if (!quoteIds.isEmpty()) {
            Map<Id, SBQQ__Quote__c> quotes = new Map<Id, SBQQ__Quote__c>([
                    SELECT Id, OwnerId, Owner.Email
                    FROM SBQQ__Quote__c
                    WHERE Id IN :quoteIds
            ]);
            List<SBQQ__QuoteLine__c> quoteLinesForUpdate = new List<SBQQ__QuoteLine__c>();
            for (Case c : fitOutCases) {
                Case oldCase = oldCases.get(c.Id);
                if (c.Complete_cost__c != oldCase.Complete_cost__c && c.Complete_cost__c
                        && quotes.containsKey(c.Quote__c)) {
                    c.Sales_Rep_on_Quote__c = quotes.get(c.Quote__c).Owner.Email;
                }
            }
        }
    }

    private void updateNetOnQuoteLine(List<Case> fitOutCases, Map<Id, Case> oldCases) {
        List<SBQQ__QuoteLine__c> quoteLinesForUpdate = new List<SBQQ__QuoteLine__c>();
        for (Case c : fitOutCases) {
            Case oldCase = oldCases.get(c.Id);
            if (c.FitOutCost__c != null && c.FitOutLink__c != null
                    && c.Complete_cost__c != oldCase.Complete_cost__c && c.Complete_cost__c) {
                quoteLinesForUpdate.add(new SBQQ__QuoteLine__c(
                        Id = c.FitOutLink__c,
                        Status__c = SBQQ_QuoteConstants.QUOTE_LINE_STATUS_COMPLETE,
                        Net_Subtotal__c = c.FitOutCost__c
                ));
            }
        }
        if (!quoteLinesForUpdate.isEmpty()) {
            SBQQ.TriggerControl.disable();
            update quoteLinesForUpdate;
            SBQQ.TriggerControl.enable();
        }
    }

    private void changeStatusOnContract(List<Case> newCases, Map<Id, Case> oldCases) {
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lease Transaction').getRecordTypeId();
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();

        for (Case oneCase : newCases) {
            if (oneCase.Status != oldCases.get(oneCase.Id).Status && oneCase.Status == Constants.STATUS_CLOSED_LOST
                    && oneCase.recordTypeId == caseRecordTypeId) {
                quoteIds.add(oneCase.Quote__c);
            }
        }
        //Define Quote related with Case
        if (!quoteIds.isEmpty()) {
            List<SBQQ__Quote__c> quotes = [
                    SELECT Id, Contract__c
                    FROM SBQQ__Quote__c
                    WHERE Id IN :quoteIds
            ];

            for (SBQQ__Quote__c quote : quotes) {
                contractIds.add(quote.Contract__c);
            }
            //Define Contract related with Quote
            if (!contractIds.isEmpty()) {
                List<Contract> contracts = [
                        SELECT Id, Status
                        FROM Contract
                        WHERE Id IN :contractIds
                        AND Status != :Constants.STATUS_NOT_COMPLETED
                ];
                //update Status on Contract
                for (Contract contract : contracts) {
                    contract.Status = Constants.STATUS_NOT_COMPLETED;
                }

                update contracts;
            }
        }
    }

    private void addEntitlementToTheSLACase(List<Case> newCases) {
        Schema.RecordTypeInfo ltCaseRecordType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lease Transaction');
        if (ltCaseRecordType == null) {
            //there is no LT(SLA) RT, exit
            return;
        }

        //filter LT Cases with no entitlement
        List<Case> ltCases = new List<Case>();
        Set<Id> accountIds = new Set<Id>();
        for (Case c : newCases) {
            if (c.RecordTypeId == ltCaseRecordType.getRecordTypeId() && c.EntitlementId == null) {
                ltCases.add(c);
                accountIds.add(c.AccountId);
            }
        }
        //select entitlements and create map account-entitlement, so we'll be able to set them to related cases
        List<Entitlement> entitlements = [select id, AccountId from Entitlement where AccountId in :accountIds];
        Map<Id, Id> accountIdEntitlementIdMap = new Map<Id, Id>();
        for (Entitlement entitlement : entitlements) {
            accountIdEntitlementIdMap.put(entitlement.AccountId, entitlement.Id);
        }

        for (Case c : ltCases) {
            c.EntitlementId = accountIdEntitlementIdMap.get(c.AccountId);
        }
        //that method used in the pre-insert, so no dml actions needed here.
    }

    private void setAssignmentDateIfAssignedToTeamMember(List<Case> newCases) { //TODO: coverage
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Lease Transaction').getRecordTypeId();
        List<CaseTeamTemplateMember> caseTeamTemplateMembers = [select TeamTemplateId, MemberId from CaseTeamTemplateMember where TeamTemplateId in:([select id from CaseTeamTemplate where Name = :LEASE_TRANSACTION_CASE_TEAM])];
        Set<Id> membersIds = new Set<Id>();


        for (CaseTeamTemplateMember member : caseTeamTemplateMembers) {
            membersIds.add(member.MemberId);
        }

        for (Case caseToCheck : newCases) {
            if (caseToCheck.recordTypeId == caseRecordTypeId && membersIds.contains(caseToCheck.OwnerId) && caseToCheck.SLA_Assignment_Time__c == null) {//assigned to the LT team first time
                caseToCheck.SLA_Assignment_Time__c = System.now();
            }
        }
    }

    private List<Case> getCasesWithNewStatus(List<Case> newCases, Map<Id, Case> oldMap, String status) {
        List<Case> updatedCases = new List<Case>();
        for (Case theCase : newCases) {
            Case oldCase = oldMap != null ? oldMap.get(theCase.Id) : null;
            if (oldCase != null && oldCase.Status != theCase.Status && theCase.Status == status) {
                updatedCases.add(theCase);
            }
        }
        return updatedCases;
    }

    private List<Case> filterCasesByRecordType(List<Case> newCases, Id recordTypeId) {
        List<Case> filterredCases = new List<Case>();
        for (Case theCase : newCases) {
            if (theCase.RecordTypeId == recordTypeId) {
                filterredCases.add(theCase);
            }
        }
        return filterredCases;
    }

    private void updateRelatedOpportunitiesForExchangedCases(List<Case> newCases) {
        updateRelatedOpportunities(newCases, false);
    }

    private void updateRelatedOpportunitiesForCompletedCases(List<Case> newCases) {
        updateRelatedOpportunities(newCases, true);
    }

    private void updateRelatedOpportunities(List<Case> newCases, Boolean caseComplete) {
        Set<Id> opportunitiesIds = SObjectUtils.getIdSetFromObjects(newCases, 'Opportunity__c');
        List<Opportunity> opportunitiesForUpdate = new List<Opportunity>();
        for (Id theOpportunityId : opportunitiesIds) {
            Opportunity theOpportunity = new Opportunity(Id = theOpportunityId, Contracts_Exchanged__c = true);
            if (caseComplete) {
                theOpportunity.LT_Case_Completed__c = true;
            }
            opportunitiesForUpdate.add(theOpportunity);
        }
        update opportunitiesForUpdate;
    }

    private void checkThatCompleteCaseHasNotOpenTasks(List<Case> cases) {
        Set<Id> completedCaseIds = getCompletedCaseIds(cases);
        Map<Id, List<Task>> tasksByCaseIds = getTasksByCaseIds(completedCaseIds);
        for (Case c : getCasesWithFollowingIds(cases, tasksByCaseIds.keySet())) {
            for (Task t : tasksByCaseIds.get(c.Id)) {
                if (t.Status == 'Open') {
                    c.Status.addError('You can\'t complete Case with open Tasks');
                }
            }
        }
    }

    private Set<Id> getCompletedCaseIds(List<Case> cases) {
        Set<Id> ids = new Set<Id>();
        for (Case c : cases) {
            if (c.Status == 'Completed' && ((Case) Trigger.oldMap.get(c.Id)).Status != 'Completed') {
                ids.add(c.Id);
            }
        }
        return ids;
    }

    private Map<Id, List<Task>> getTasksByCaseIds(Set<Id> caseIds) {
        List<Task> tasks = [SELECT Id, Status, WhatId FROM Task WHERE WhatId In :caseIds];
        Map<Id, List<Task>> tasksByCaseIds = new Map<Id, List<Task>>();
        for (Task t : tasks) {
            if (tasksByCaseIds.containsKey(t.WhatId)) {
                tasksByCaseIds.get(t.WhatId).add(t);
            } else {
                List<Task> taskList = new List<Task>{
                        t
                };
                tasksByCaseIds.put(t.WhatId, taskList);
            }
        }
        return tasksByCaseIds;
    }

    private List<Case> getCasesWithFollowingIds(List<Case> cases, Set<Id> ids) {
        List<Case> result = new List<Case>();
        for (Case c : cases) {
            if (ids.contains(c.Id)) {
                result.add(c);
            }
        }
        return result;
    }

    private void setContactInformation(list<Case> cases) {
        Set<Id> recordTypesToFilter = new Set<Id>{
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.DESIGN_RECORD_TYPE),
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.FIT_OUT_DESIGN_RECORD_TYPE),
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.BUILDING_CONSTRUCTION_CASE_RECORD_TYPE)
        };

        List<Case> filteredCases = SObjectUtils.filterRecordsByRecordType(cases, recordTypesToFilter);
        Map<Id, Case> quoteIdToCase = new Map<Id, Case>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<Contact>> contactsMap = new Map<Id, List<Contact>>();
        Map<Id, SBQQ__Quote__c> quotes = new Map<Id, SBQQ__Quote__c>();

        for (Case theCase : filteredCases) {
            if ((theCase.Sales_COntact__c == null || theCase.ContactId == null) && theCase.Quote__c != null) {
                quoteIdToCase.put(theCase.Quote__c, theCase);
            }
        }

        if (!quoteIdToCase.isEmpty()) {
            quotes = new Map<Id, SBQQ__Quote__c>([
                SELECT Id, SBQQ__PrimaryContact__c, SBQQ__Opportunity2__r.AccountId, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE Id IN:quoteIdToCase.keySet()
            ]);
        }

        for (SBQQ__Quote__c quote : quotes.values()) {
            if (quote.SBQQ__Opportunity2__r.AccountId != null) {
                accountIds.add(quote.SBQQ__Opportunity2__r.AccountId);
            }
        }
        if (!accountIds.isEmpty()) {
            contactsMap = ContactService.getProjectManagementContactsMap(accountIds);
        }

        for (Case theCase : quoteIdToCase.values()) {
            SBQQ__Quote__c quote = quotes.get(theCase.Quote__c);
            if (quote != null) {
                if (theCase.Sales_COntact__c == null && quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_ACCEPTED) {
                    theCase.Sales_COntact__c = quote.SBQQ__PrimaryContact__c;
                }

                Id accountId = quote.SBQQ__Opportunity2__r.AccountId;
                if (theCase.ContactId == null && accountId != null && contactsMap.containsKey(accountId)) {

                    Contact pmContact = !contactsMap.get(quote.SBQQ__Opportunity2__r.AccountId).isEmpty()
                            ? contactsMap.get(quote.SBQQ__Opportunity2__r.AccountId).get(0)
                            : null;

                    theCase.ContactId = pmContact != null ? pmContact.Id : null;
                }
            }
        }
    }

    private List<Case> getLeaseTransactionCases(List<Case> updatedCases) {
        List<Case> leaseTransactionCases = filterCasesByRecordType(updatedCases, RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.LEASE_TRANSACTION_RECORD_TYPE));
        List<Case> outsourcedLeaseTransactionCases = filterCasesByRecordType(updatedCases, RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.OUTSOURCED_LEASE_TRANSACTION_RECORD_TYPE));
        List<Case> allLTCases = new List<Case>(leaseTransactionCases);
        allLTCases.addAll(outsourcedLeaseTransactionCases);
        return allLTCases;
    }
}