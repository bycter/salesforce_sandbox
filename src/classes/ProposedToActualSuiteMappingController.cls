public class ProposedToActualSuiteMappingController {
    public Proposed_to_Actual_Suite_Mapping__c searchMapping { get; set; }
    public Inventory__c proposedSuite { get; set; }
    public String[] selectedSuitesIds { get; set; }

    private Id actualRecordTypeId = Schema.SObjectType.Inventory__c.getRecordTypeInfosByName().get('Actual Suite').getRecordTypeId();
    private Id proposedRecordTypeId = Schema.SObjectType.Inventory__c.getRecordTypeInfosByName().get('Proposed Suite').getRecordTypeId();

    public ProposedToActualSuiteMappingController() {
        searchMapping = new Proposed_to_Actual_Suite_Mapping__c();
        Id proposedSuiteId = ApexPages.currentPage().getParameters().get('proposedSuiteId');
        populateProposedSuite(proposedSuiteId);
        populateSelectedSuites(proposedSuiteId);
    }

    public List<SelectOption> getActualSuites() {
        List<SelectOption> options = new List<SelectOption>();

        if (searchMapping.Proposed_Suite__c == null) {
            return options;
        }

        List<Inventory__c> actualSuites = [
                select Id, Name
                from Inventory__c
                where RecordTypeId = :actualRecordTypeId and Property__c = :proposedSuite.Property__c and Sales_Status__c != 'Not Available' and Sales_Status__c != 'Not for Sale'
        ];
        for (Inventory__c actualSuite : actualSuites) {
            options.add(new SelectOption(actualSuite.id, actualSuite.Name));
        }
        return options;
    }

    public PageReference save() {
        if (searchMapping.Proposed_Suite__c == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select a proposed suite'));
            return null;
        }
        List<Proposed_to_Actual_Suite_Mapping__c> mappingsToRemove = [select Id, Actual_Suite__c, Proposed_Suite__c, Name from Proposed_to_Actual_Suite_Mapping__c where Proposed_Suite__c = :searchMapping.Proposed_Suite__c and Actual_Suite__c not in :selectedSuitesIds];
        delete mappingsToRemove;

        List<Proposed_to_Actual_Suite_Mapping__c> existingMappings = [select Id, Actual_Suite__c, Proposed_Suite__c, Name from Proposed_to_Actual_Suite_Mapping__c where Proposed_Suite__c = :searchMapping.Proposed_Suite__c and Actual_Suite__c in :selectedSuitesIds];
        Set<Id> alreadyLinkedActualSuitsIds = new Set<Id>();

        for (Proposed_to_Actual_Suite_Mapping__c existingMapping : existingMappings) {
            alreadyLinkedActualSuitsIds.add(existingMapping.Actual_Suite__c);
        }

        Map<Id, Inventory__c> actualSuites = new Map<Id, Inventory__c>([select Id, Name from Inventory__c where Id in:selectedSuitesIds]);

        List<Proposed_to_Actual_Suite_Mapping__c> mappingsToCreate = new List<Proposed_to_Actual_Suite_Mapping__c>();
        for (Id actualSuiteId : selectedSuitesIds) {
            if (!alreadyLinkedActualSuitsIds.contains(actualSuiteId)) {
                Proposed_to_Actual_Suite_Mapping__c mapping =
                        new Proposed_to_Actual_Suite_Mapping__c(Actual_Suite__c = actualSuiteId,
                                Proposed_Suite__c = searchMapping.Proposed_Suite__c,
                                Name = ('Link to ' + actualSuites.get(actualSuiteId).Name));
                mappingsToCreate.add(mapping);
            }
        }
        insert mappingsToCreate;
        return new PageReference('/' + searchMapping.Proposed_Suite__c);
    }

    public PageReference cancel() {
        String id = searchMapping.Proposed_Suite__c != null ? searchMapping.Proposed_Suite__c : '';
        return new PageReference('/' + id);
    }

    public void rerenderActualSuites() {
        populateProposedSuite(searchMapping.Proposed_Suite__c);
        populateSelectedSuites(searchMapping.Proposed_Suite__c);
    }

    private void populateProposedSuite(Id id) {
        List<Inventory__c> proposedSuiteList = [
                select Id, Name, Property__c, RecordTypeId
                from Inventory__c
                where id = :id and RecordTypeId = :proposedRecordTypeId
        ];

        if (!proposedSuiteList.isEmpty()) {
            proposedSuite = proposedSuiteList.get(0);
            searchMapping.Proposed_Suite__c = proposedSuite.Id;
        }
    }

    private void populateSelectedSuites(Id proposedSuiteId) {
        List<Proposed_to_Actual_Suite_Mapping__c> mappings = findMappingsForProposedSuite(proposedSuiteId);
        selectedSuitesIds = new String[]{
        };
        for (Proposed_to_Actual_Suite_Mapping__c mapping : mappings) {
            selectedSuitesIds.add(mapping.Actual_Suite__c);
        }
    }

    private List<Proposed_to_Actual_Suite_Mapping__c> findMappingsForProposedSuite(Id suiteId) {
        return [select Id, Actual_Suite__c, Proposed_Suite__c, Name from Proposed_to_Actual_Suite_Mapping__c where Proposed_Suite__c = :suiteId];
    }
}