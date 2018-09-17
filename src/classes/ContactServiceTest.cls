/**
 * @description Test class for ContactService
 */
@isTest
private class ContactServiceTest {

    @testSetup
    private static void setupData() {
        Account testAccount = RecordDmlTest.createAccount();
        List<Contact> testContacts = new List<Contact> {
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_LC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_ILPC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_OOHC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_BC)
        };
        insert testContacts;
    }

    @isTest
    private static void testGetCustomerContactsMap() {
        Map<Id, Account> testAccountsMap = new Map<Id, Account>([SELECT Id FROM Account]);
        ContactService theContactService = new ContactService();
        Map<Id, List<Contact>> contactsMap = theContactService.getCustomerContactsMap(testAccountsMap.keySet());

        System.assertNotEquals(true, contactsMap.isEmpty());
        System.assertNotEquals(true, contactsMap.get(testAccountsMap.values()[0].Id).isEmpty());
    }
}