public with sharing class GenerateQuoteController {

    public static final String NEW_DEAL = 'New_deal';
    public static final String CONTRACT_OPTIONS = 'contractOptions';
    public static final String SELECT_CONTRACTS = 'selectContracts';
    public static final String SELECT_MASTER_CONTRACT = 'selectMasterContract';
    public static final String VIEWING_SELECTION = 'viewingSelection';
    public static final String NO_VIEWING_COMMENT = 'noViewingComment';
    public static final String PROPERTY_CONTACT_SELECTION = 'propertyContactSelection';
    public static final String DONE = 'done';

    public Opportunity opportunity { get; set; }
    public View currentView { get; set; }
    public String contractOption { get; set; }
    public String[] selectedContractsIds { get; set; }
    public String selectMasterContract { get; set; }
    public Id selectedViewingId { get; set; }
    public String selectedProperty { get; set; }
    public Id selectedContactId { get; set; }
    public String noViewingComment { get; set; }

    private Map<Id, Contract> contractsMap;
    private Map<Id, Event> viewingsMap;
    private Map<String, Id> propertyMap;
    private Map<Id, Contact> contactMap;

    private SBQQ__Quote__c quote;


    public GenerateQuoteController() {
        String opportunityId = ApexPages.currentPage().getParameters().get('Id');
        opportunity = findOpportunityById(opportunityId);
        contractsMap = findActiveContracts(opportunityId);
        viewingsMap = findViewings(opportunityId);
        propertyMap = findProperties();
        contactMap = findContacts(opportunity);
        quote = null;
        contractOption = NEW_DEAL;
        setInitialView();
    }

    @TestVisible
    private static Opportunity findOpportunityById(Id opportunityId) {
        List<Opportunity> opportunities = [
                select Id, Region__c, RecordTypeId, AccountId, Type, Pricebook2Id, RecordType.DeveloperName, Name,
                        Account.Name
                from Opportunity
                where Id = :opportunityId
        ];
        if (opportunities.size() != 0) {
            return opportunities.get(0);
        }
        return null;
    }

    private Map<Id, Contract> findActiveContracts(Id opportunityId) {
        if (String.isBlank(opportunityId)) {
            return new Map<Id, Contract>();
        }

        return new Map<Id, Contract>([
                select Id, Name
                from Contract
                where AccountId = :opportunity.AccountId
                and Pricebook2Id = :opportunity.Pricebook2Id
                and (Status = 'Activated' OR Status = 'Live')
                order by CreatedDate desc
        ]);
    }

    private Map<Id, Event> findViewings(Id opportunityId) {
        if (String.isBlank(opportunityId)) {
            return new Map<Id, Event>();
        }
        return new Map<Id, Event>([
                SELECT Id, Property__c, WhoId, Subject
                FROM Event
                WHERE IsChild = false
                and RecordType.DeveloperName = 'Viewing'
                and Status__c = 'Completed'
                and WhatId = :opportunityId
        ]);
    }

    private Map<String, Id> findProperties() {
        Map<String, Id> nameIdMap = new Map<String, Id>();
        for (Property__c property : [select Id, Name from Property__c where Active__c = true]) {
            nameIdMap.put(property.Name, property.Id);
        }
        return nameIdMap;
    }

    private Map<Id, Contact> findContacts(Opportunity opportunity) {
        if (opportunity == null || opportunity.AccountId == null) {
            return new Map<Id, Contact>();
        }

        List<AccountContactRelation> accountContacts = new List<AccountContactRelation>(
        [SELECT Id, ContactId, Contact.LastName, Contact.FirstName, Contact.Name FROM AccountContactRelation WHERE Contact.Active__c = true
            AND AccountId = :opportunity.AccountId
            AND IsActive = true]);

        Set<Id> contactIds = SObjectUtils.getIdSetFromObjects(accountContacts, 'ContactId');

        return new Map<Id, Contact> ([SELECT Id, Name FROM Contact WHERE Id IN : contactIds]);
    }

    public void next() {
        if (currentView.isValidToGoNext(this)) {
            currentView = currentView.goNext(String.isBlank(selectedViewingId), contractOption);
            if (currentView.name == DONE) {
                quote = generateQuote();
            }
        }
    }

    public void back() {
        if (currentView.previousView != null) {
            currentView = currentView.previousView;
        }
    }

    public PageReference finish() {
        return new PageReference('/' + quote.Id);
    }

    public List<SelectOption> getContractOptions() {
        List<SelectOption> contractsOptions = new List<SelectOption>();
        for (Id contractId : contractsMap.keySet()) {
            contractsOptions.add(new SelectOption(contractId, contractsMap.get(contractId).Name));
        }
        return contractsOptions;
    }

    public List<SelectOption> getSelectedContractOptions() {
        List<SelectOption> contractsOptions = new List<SelectOption>();
        for (Id contractId : selectedContractsIds) {
            contractsOptions.add(new SelectOption(contractId, contractsMap.get(contractId).Name));
        }
        return contractsOptions;
    }

    public List<SelectOption> getViewingOptions() {
        List<SelectOption> viewingOptions = new List<SelectOption>();
        for (Id viewingId : viewingsMap.keySet()) {
            viewingOptions.add(new SelectOption(viewingId, viewingsMap.get(viewingId).Subject));
        }
        viewingOptions.add(new SelectOption('', 'No Viewing Required'));
        return viewingOptions;
    }

    public Set<String> getProperties() {
        return propertyMap.keySet();
    }

    public List<SelectOption> getContactOptions() {
        List<SelectOption> contactOptions = new List<SelectOption>();
        for (Id contactId : contactMap.keySet()) {
            contactOptions.add(new SelectOption(contactId, contactMap.get(contactId).Name));
        }
        return contactOptions;
    }

    private SBQQ__Quote__c generateQuote() {
        if (contractOption != NEW_DEAL) {// we have to generate quote from contracts
            return QuoteFromContractCreator.generate(opportunity, selectMasterContract, selectedContractsIds, contractOption);
        }
        SBQQ__Quote__c generatedQuote = new SBQQ__Quote__c();
        generatedQuote.Property__c = propertyMap.get(selectedProperty);
        generatedQuote.SBQQ__Type__c = contractOption;
        generatedQuote.Surrender_Premium__c = null; //TODO: Why do we need to clear these fields?
        generatedQuote.Surrender_deed_due_date__c = null;
        generatedQuote.Surrender_deed_weeks__c = null;
        generatedQuote.RecordTypeId = RecordTypeHelper.getSbqqQuoteRtIdByDeveloperName(opportunity.RecordType.DeveloperName);
        generatedQuote.SBQQ__Opportunity2__c = opportunity.Id;
        if (selectedViewingId == null) {
            generatedQuote.No_Viewing_Required_Comment__c = noViewingComment;
            generatedQuote.SBQQ__PrimaryContact__c = selectedContactId;
        } else {
            generatedQuote.Property__c = viewingsMap.get(selectedViewingId).Property__c;
            Id primaryContact = viewingsMap.get(selectedViewingId).WhoId;
            if (primaryContact != null && Contact.getSObjectType() == primaryContact.getSobjectType()) {
                generatedQuote.SBQQ__PrimaryContact__c = primaryContact;
            }
        }
        insert generatedQuote;
        return generatedQuote;
    }

    private class View {
        public String name { get; set; }
        public View previousView { get; set; }

        public View(String name) {
            this.name = name;
            previousView = null;
        }

        public View(String name, View view) {
            this.name = name;
            previousView = view;
        }

        public View goNext(Boolean noViewingRequired, String contractOption) {
            String newViewName = '';

            if (name == CONTRACT_OPTIONS) {
                if (contractOption == NEW_DEAL) {
                    newViewName = VIEWING_SELECTION;
                } else {
                    newViewName = SELECT_CONTRACTS;
                }
            }

            if (name == VIEWING_SELECTION) {
                if (noViewingRequired) {
                    newViewName = NO_VIEWING_COMMENT;
                } else {
                    newViewName = DONE;
                }
            }
            if (name == SELECT_CONTRACTS) {
                newViewName = SELECT_MASTER_CONTRACT;
            }

            if (name == SELECT_MASTER_CONTRACT || name == PROPERTY_CONTACT_SELECTION) {
                newViewName = DONE;
            }

            if (name == NO_VIEWING_COMMENT) {
                newViewName = PROPERTY_CONTACT_SELECTION;
            }

            return new View(newViewName, this);
        }

        private Boolean isValidToGoNext(GenerateQuoteController c) {
            if (name == PROPERTY_CONTACT_SELECTION && c.propertyMap.get(c.selectedProperty) == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Please select valid property'));
                return false;
            }
            if (name == PROPERTY_CONTACT_SELECTION && String.isBlank(c.selectedContactId)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Please select a contact'));
                return false;
            }
            if (name == SELECT_CONTRACTS && c.selectedContractsIds.IsEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ' Please select a contract'));
                return false;
            }
            return true;
        }
    }

    private void setInitialView() {
        if (opportunity.Type == 'Existing Customer') {
            currentView = new View(CONTRACT_OPTIONS);
        } else {
            currentView = opportunity.RecordType.DeveloperName == 'Virtual' ? new View(PROPERTY_CONTACT_SELECTION) : new View(VIEWING_SELECTION);
        }
    }
}