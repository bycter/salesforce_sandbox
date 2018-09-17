/**
 * @description Class contains general functionality related to Potential_Contact__c object
 */
public with sharing class PotentialContactService {

    /**
     * @description Created Potential_Contact__c record for quote documents where contact information was updated
     */
    public void createPotentialContactsForUpdatedDocuments(Map<SBQQ__QuoteDocument__c, Set<String>> updatedDocumentsMap, Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap) {
        List<Potential_Contact__c> potentialContacts = new List<Potential_Contact__c>();
        for ( SBQQ__QuoteDocument__c theDocument : updatedDocumentsMap.keySet() ) {
            potentialContacts.addAll(createPotentialContactsForUpdatedDocument(theDocument, updatedDocumentsMap.get(theDocument), oldDocumentsMap));
        }
        insert potentialContacts;
        createRemindersForNewPotentialContacts(potentialContacts, oldDocumentsMap);
    }

    /**
     * @description Returns Potential_Contact__c record for quote documents where contact information was updated
     */
    private List<Potential_Contact__c> createPotentialContactsForUpdatedDocument(SBQQ__QuoteDocument__c quoteDocument, Set<String> contactTypes, Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap) {
        List<Potential_Contact__c> potentialContacts = new List<Potential_Contact__c>();
        Set<String> potentialContactUniqueIdentifier = new Set<String>();
        SBQQ__QuoteDocument__c oldDocument = oldDocumentsMap.get(quoteDocument.Id);
        for ( String contactType : contactTypes ) {
            Potential_Contact__c potentialContact = new Potential_Contact__c();
            String uniqueIdentifier = '';
            for ( String fieldName : SBQQ_QuoteConstants.FIELD_NAMES_MAP.keySet() ) {
                potentialContact.SBQQ_Quote__c = quoteDocument.SBQQ__Quote__c;
                potentialContact.SBQQ_QuoteDocument__c = quoteDocument.Id;
                potentialContact.Account__c = quoteDocument.Account_Id__c;
                potentialContact.put(fieldName, oldDocument.get(contactType + '_' + fieldName));
                potentialContact.put('New_' + fieldName, quoteDocument.get(contactType + '_' + fieldName));
                uniqueIdentifier += quoteDocument.get(contactType + '_' + fieldName) + '_';
            }
            uniqueIdentifier = uniqueIdentifier.toLowerCase();
            System.debug('uniqueIdentifier: ' + uniqueIdentifier);
            potentialContact.Contact_Type__c = SBQQ_QuoteConstants.PREFIX_TO_CONTACT_TYPE_MAP.get(contactType);
            potentialContact.New_Contact_Type__c = SBQQ_QuoteConstants.PREFIX_TO_CONTACT_TYPE_MAP.get(contactType);
            if ( !potentialContactUniqueIdentifier.contains(uniqueIdentifier)
                    && String.isNotBlank((String)potentialContact.get('New_Last_Name__c'))
                    && String.isNotBlank((String)potentialContact.get('New_First_Name__c'))
                    && String.isNotBlank((String)potentialContact.get('New_Email__c'))) {
                potentialContacts.add(potentialContact);
                potentialContactUniqueIdentifier.add(uniqueIdentifier);
            }
        }
        return potentialContacts;
    }

    private void createRemindersForNewPotentialContacts(List<Potential_Contact__c> potentialContacts, Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap) {
        List<Task> reminderTasks = new List<Task>();
        for ( Potential_Contact__c potentialContact : potentialContacts ) {
            reminderTasks.add(TaskService.generateReviewPCTask(oldDocumentsMap.get(potentialContact.SBQQ_QuoteDocument__c).Opportunity_Owner_Id__c, potentialContact.Id));
        }
        insert reminderTasks;
    }

}