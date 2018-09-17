public with sharing class ContractTriggerHandler extends TriggerHandler {

    public static final String CONTRACT_API_NAME = 'Contract';

    public static final String ACTIVATED_STATUS = 'Activated';
    public static final String LIVE_STATUS = 'Live';

    public static final String ACTIVATED_RT_DEV_NAME = 'Activated';
    public static final String NOT_ACTIVATED_RT_DEV_NAME = 'Not_Activated';

    public static final List<String> ACTIVATED_STATUSES = new List<String>{
            ACTIVATED_STATUS, LIVE_STATUS
    };

    protected override void beforeInsert() {
        setRT((List<Contract>) Trigger.new);
    }

    protected override void afterInsert() {
        List<Contract> activatedContracts = new List<Contract>();
        for (Contract contract : (List<Contract>) Trigger.new) {
            if (ACTIVATED_STATUSES.contains(contract.Status)) { //TODO: Temporary Enabled Live status
                activatedContracts.add(contract);
            }
        }
        validationSubscriptionBeforeActivateContract(activatedContracts);
    }

    protected override void beforeUpdate() {
        List<Contract> activatedContracts = getContractsWithStatusChangedTo((List<Contract>) Trigger.new, (Map<Id, Contract>) Trigger.oldMap, ACTIVATED_STATUSES); //TODO: Temporary Enabled Live status
        validationSubscriptionBeforeActivateContract(activatedContracts);
        deactivateOldContractsIfSurrenderAndRegrant(activatedContracts);
        setRT((List<Contract>) Trigger.new);
    }

    protected override void afterUpdate() {
        List<Contract> activatedContracts = getContractsWithStatusChangedTo((List<Contract>) Trigger.new, (Map<Id, Contract>) Trigger.oldMap, ACTIVATED_STATUSES); //TODO: Temporary Enabled Live status
        updateRelatedOpportunities(activatedContracts);
        updateOnboardingCases(activatedContracts);
    }

    private void setRT(List<Contract> contracts) {
        for (Contract contract : contracts) {
            String recordTypeDevName = ACTIVATED_STATUSES.contains(contract.Status) ? ACTIVATED_RT_DEV_NAME : NOT_ACTIVATED_RT_DEV_NAME; //TODO: Temporary Enabled Live status
            contract.RecordTypeId = RecordTypeHelper.getRtIdByDeveloperName(CONTRACT_API_NAME, recordTypeDevName);
        }
    }

    private void validationSubscriptionBeforeActivateContract(List<Contract> newContracts) {
        Map<Id, Contract> activateContracts = new Map<Id, Contract>(newContracts);
        if (activateContracts != null && !activateContracts.isEmpty()) {
            List<SBQQ__Subscription__c> subscriptions = [
                    SELECT Id,
                            SBQQ__Contract__c,
                            SBQQ__Quantity__c,
                            SBQQ__UnitCost__c,
                            First_Bill_Date__c,
                            SBQQ__BillingType__c,
                            SBQQ__BillingFrequency__c
                    FROM SBQQ__Subscription__c
                    WHERE SBQQ__Contract__c IN :activateContracts.keySet()
            ];

            Map<Id, List<SBQQ__Subscription__c>> contractToSubscriptions = SObjectUtils.getIdMapFromObjects(subscriptions, 'SBQQ__Contract__c');
            for (Contract contract : activateContracts.values()) {
                if (contractToSubscriptions.containsKey(contract.Id)) {
                    for (SBQQ__Subscription__c subscription : contractToSubscriptions.get(contract.Id)) {
                        if (subscription.SBQQ__Quantity__c == null
                                || subscription.SBQQ__UnitCost__c == null
                                || subscription.First_Bill_Date__c == null
                                || String.isBlank(subscription.SBQQ__BillingType__c)
                                || String.isBlank(subscription.SBQQ__BillingFrequency__c)) {
                            contract.addError(Label.YouCannotActivateContractCheckSubscriptionLines);
                        }
                    }
                }
            }
        }
    }

    private void deactivateOldContractsIfSurrenderAndRegrant(List<Contract> activatedContracts) {
        Set<Id> quotesIds = new Set<Id>();
        for (Contract c : activatedContracts) {
            quotesIds.add(c.SBQQ__Quote__c);
        }

        List<ContractToQuote__c> contractToQuoteList = new List<ContractToQuote__c>([SELECT Id, Contract__c FROM ContractToQuote__c WHERE Quote__c IN:quotesIds]);
        Set<Id> contractIds = new Set<Id>();
        for (ContractToQuote__c contractToQuote : contractToQuoteList) {
            contractIds.add(contractToQuote.Contract__c);
        }

        List<Contract> contractsToDeactivate = [SELECT Id, Status, OwnerId FROM Contract WHERE Id IN:contractIds];

        for (Contract contract : contractsToDeactivate) {
            contract.Status = 'Inactive';
        }

        update contractsToDeactivate;
        createTasksForOwners(contractsToDeactivate);
    }

    private void createTasksForOwners(List<Contract> deactivatedContracts) {
        List<Task> tasks = new List<Task>();

        for (Contract contract : deactivatedContracts) {
            Task task = new Task(Status = 'Open', WhatId = contract.Id, Subject = 'Contract was inactivated during Surrender & Regrant');
            tasks.add(task);
        }

        insert tasks;
    }

    private List<Contract> getContractsWithStatusChangedTo(List<Contract> newContracts, Map<Id, Contract> oldContractsMap, List<String> statuses) {
        List<Contract> filterredContacts = new List<Contract>();
        for (Contract theContract : newContracts) {
            Contract oldContract = oldContractsMap != null ? oldContractsMap.get(theContract.Id) : null;
            if (oldContract != null && oldContract.Status != theContract.Status && statuses.contains(theContract.Status)) {
                filterredContacts.add(theContract);
            }
        }
        return filterredContacts;
    }

    private void updateRelatedOpportunities(List<Contract> newContracts) {
        Set<Id> quoteIds = SObjectUtils.getIdSetFromObjects(newContracts, 'SBQQ__Quote__c');
        List<SBQQ__Quote__c> parentQuotes = [SELECT SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds];
        Map<Id, Id> quoteIdToOpportunityIdMap = new Map<Id, Id>();
        for (SBQQ__Quote__c theQuote : parentQuotes) {
            quoteIdToOpportunityIdMap.put(theQuote.Id, theQuote.SBQQ__Opportunity2__c);
        }

        Set<Opportunity> opportunities = new Set<Opportunity>();
        for (Id opportunityId : quoteIdToOpportunityIdMap.values()) {
            if (opportunityId != null) {
                opportunities.add(new Opportunity(
                        Id = opportunityId,
                        Contract_Activated__c = true
                ));
            }
        }
        update new List<Opportunity>(opportunities);
    }

    /**
     * @description Sets "Ready to Onboard" status for related Serviced Space Onboarding Cases
     */
    private void updateOnboardingCases(List<Contract> activatedContracts) {
        Set<Id> activatedContractIds = new Map<Id, Contract>(activatedContracts).keySet();
        Id servicedSpaceOnboardingRTId = RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.SERVICED_SPACE_ONBOARDING_RECORD_TYPE);
        List<Case> serviceSpaceOnboardingCases = [SELECT Id
                                                  FROM Case
                                                  WHERE Quote__r.Contract__c IN :activatedContractIds AND RecordTypeId = :servicedSpaceOnboardingRTId];
        for ( Case theCase : serviceSpaceOnboardingCases ) {
            theCase.Status = CaseService.STATUS_READY_TO_ONBOARD;
        }
        update serviceSpaceOnboardingCases;
    }
}