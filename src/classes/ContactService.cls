/**
 * @description Class contains general functionality related to Contact object
 */
public with sharing class ContactService {

    private static Map<Id, List<Contact>> accountIdToContactsMap { get; set; }

    /**
     * @description Returns a map of Contacts grouped by accountId
     */
    public Map<Id, List<Contact>> getCustomerContactsMap(Set<Id> accountIds) {
        Map<Id, List<Contact>> contactsMap = new Map<Id, List<Contact>>();
        List<Contact> contacts = [
                SELECT AccountId, FirstName, LastName, Email, Phone, MobilePhone, Contact_Type__c, Contact_Preference__c
                FROM Contact
                WHERE AccountId IN :accountIds AND
                Contact_Type__c INCLUDES (:SBQQ_QuoteConstants.CONTACT_TYPE_LC, :SBQQ_QuoteConstants.CONTACT_TYPE_PMC, :SBQQ_QuoteConstants.CONTACT_TYPE_ILPC,
                        :SBQQ_QuoteConstants.CONTACT_TYPE_OOHC, :SBQQ_QuoteConstants.CONTACT_TYPE_BC)
        ];
        for (Contact theContact : contacts) {
            if (!contactsMap.containsKey(theContact.AccountId)) {
                contactsMap.put(theContact.AccountId, new List<Contact>());
            }
            contactsMap.get(theContact.AccountId).add(theContact);
        }
        return contactsMap;
    }

    /**
     * @description Returns a map of Contacts with Contact_Type__c = Project Management Contact grouped by AccountId
     */
    public static Map<Id, List<Contact>> getProjectManagementContactsMap(Set<Id> accountIds) {
        if ( accountIdToContactsMap == null || !isContactsSelected(accountIds) ) {
            accountIdToContactsMap = getContactsMap(accountIds);
        }
        return filterContactsByType(accountIds, SBQQ_QuoteConstants.CONTACT_TYPE_PMC);
    }

    /**
     * @description Returns a map of Contacts with Contact_Type__c = Director Contact grouped by AccountId
     */
    public Map<Id, List<Contact>> getCompanyDirectorsMap(Set<Id> accountIds) {
        if ( accountIdToContactsMap == null || !isContactsSelected(accountIds) ) {
            accountIdToContactsMap = getContactsMap(accountIds);
        }
        return filterContactsByType(accountIds, SBQQ_QuoteConstants.CONTACT_TYPE_CD);
    }

    public static Map<Id, List<Contact>> getInLifePropertyContactsMap(Set<Id> accountIds) {
        if ( accountIdToContactsMap == null || !isContactsSelected(accountIds) ) {
            accountIdToContactsMap = getContactsMap(accountIds);
        }
        return filterContactsByType(accountIds, SBQQ_QuoteConstants.CONTACT_TYPE_ILPC);
    }

    public static Map<Id, List<Contact>> getLegalContactsMap(Set<Id> accountIds) {
        if ( accountIdToContactsMap == null || !isContactsSelected(accountIds) ) {
            accountIdToContactsMap = getContactsMap(accountIds);
        }
        return filterContactsByType(accountIds, SBQQ_QuoteConstants.CONTACT_TYPE_LC);
    }

    private static Boolean isContactsSelected(Set<Id> accountIds) {
        for ( Id accountId : accountIds ) {
            if ( !accountIdToContactsMap.containsKey(accountId) ) {
                return false;
            }
        }
        return true;
    }

    private static Map<Id, List<Contact>> getContactsMap(Set<Id> accountIds) {
        Map<Id, List<Contact>> contactsMap = new Map<Id, List<Contact>>();
        List<Contact> contacts = [
                SELECT AccountId, Contact_Type__c, FirstName, LastName, Email
                FROM Contact
                WHERE AccountId IN :accountIds
        ];
        for (Contact theContact : contacts) {
            if (!contactsMap.containsKey(theContact.AccountId)) {
                contactsMap.put(theContact.AccountId, new List<Contact>());
            }
            contactsMap.get(theContact.AccountId).add(theContact);
        }
        return contactsMap;
    }

    private static Map<Id, List<Contact>> filterContactsByType(Set<Id> accountIds, String contactType) {
        Map<Id, List<Contact>> contactsMap = new Map<Id, List<Contact>>();
        for ( Id accountId : accountIds ) {
            if ( accountIdToContactsMap.containsKey(accountId) ) {
                for ( Contact theContact : accountIdToContactsMap.get(accountId) ) {
                    if ( String.isBlank(theContact.Contact_Type__c) || !theContact.Contact_Type__c.containsIgnoreCase(contactType) ) {
                        continue;
                    }
                    if (!contactsMap.containsKey(theContact.AccountId)) {
                        contactsMap.put(theContact.AccountId, new List<Contact>());
                    }
                    contactsMap.get(theContact.AccountId).add(theContact);
                }
            }
        }
        return contactsMap;
    }

    public static void cleanup() {
        accountIdToContactsMap = null;
    }
}