/**
 * @description Test class fro PotentialContactService
 */
@isTest
private class PotentialContactServiceTest {

    @testSetup
    public static void setupData() {
        Account testAccount = RecordDmlTest.createAccount();
        List<Contact> testContacts = new List<Contact> {
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_LC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_ILPC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_OOHC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_BC)
        };
        insert testContacts;
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);

        Test.startTest();
        SBQQ.TriggerControl.disable();
        quote.SBQQ__Account__c = testAccount.Id;
        update quote;
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c= quote.Id
        );
        insert quoteDocument;
        Test.stopTest();    
    }

    @isTest
    private static void testCreatioOfPotentialCustomers() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
        Map<Id, SBQQ__QuoteDocument__c> quoteDocumentsMap = new Map<Id, SBQQ__QuoteDocument__c>([SELECT LC_First_Name__c, LC_Last_Name__c, LC_Email__c, LC_Phone__c, LC_Mobile__c, LC_Contact_Preference__c,
                                                                                                        BC_First_Name__c, BC_Last_Name__c, BC_Email__c, BC_Phone__c, BC_Mobile__c, BC_Contact_Preference__c,
                                                                                                        PMC_First_Name__c, PMC_Last_Name__c, PMC_Email__c, PMC_Phone__c, PMC_Mobile__c, PMC_Contact_Preference__c,
                                                                                                        ILPC_First_Name__c, ILPC_Last_Name__c, ILPC_Email__c, ILPC_Phone__c, ILPC_Mobile__c, ILPC_Contact_Preference__c,
                                                                                                        OOHC_First_Name__c, OOHC_Last_Name__c, OOHC_Email__c, OOHC_Phone__c, OOHC_Mobile__c, OOHC_Contact_Preference__c,
                                                                                                        SBQQ__Quote__c, Opportunity_Owner_Id__c
                                                                                                FROM SBQQ__QuoteDocument__c]);
        List<SBQQ__QuoteDocument__c> newQuoteDocuments = quoteDocumentsMap.values().deepClone(true);
        for ( SBQQ__QuoteDocument__c theDocument : newQuoteDocuments ) {
            theDocument.LC_First_Name__c = 'Test new';
            theDocument.LC_Last_Name__c = 'Contact';
            theDocument.BC_Email__c = 'test@test.com';
            theDocument.BC_Phone__c = '987654321';
        }
        SBQQ_QuoteDocumentService theDocumentService = new SBQQ_QuoteDocumentService();
        Map<SBQQ__QuoteDocument__c, Set<String>> updatedDocumentsMap = theDocumentService.getDocumentsWithUpdatedContactInfo(quoteDocumentsMap, newQuoteDocuments);

        //when
        Test.startTest();
        PotentialContactService thePotentialContactService = new PotentialContactService();
        thePotentialContactService.createPotentialContactsForUpdatedDocuments(updatedDocumentsMap, quoteDocumentsMap);

        //then
        List<Potential_Contact__c> potentialContacts = [SELECT First_Name__c, Last_Name__c, New_First_Name__c, New_Last_Name__c
                                                        FROM Potential_Contact__c];
        System.assertNotEquals(true, potentialContacts.isEmpty());
        System.assertEquals(2, potentialContacts.size());
        Test.stopTest();
    }

    @isTest
    private static void testCreatioOfSamePotentialCustomers() {
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
        Map<Id, SBQQ__QuoteDocument__c> quoteDocumentsMap = new Map<Id, SBQQ__QuoteDocument__c>([SELECT LC_First_Name__c, LC_Last_Name__c, LC_Email__c, LC_Phone__c, LC_Mobile__c, LC_Contact_Preference__c,
                                                                                                        BC_First_Name__c, BC_Last_Name__c, BC_Email__c, BC_Phone__c, BC_Mobile__c, BC_Contact_Preference__c,
                                                                                                        PMC_First_Name__c, PMC_Last_Name__c, PMC_Email__c, PMC_Phone__c, PMC_Mobile__c, PMC_Contact_Preference__c,
                                                                                                        ILPC_First_Name__c, ILPC_Last_Name__c, ILPC_Email__c, ILPC_Phone__c, ILPC_Mobile__c, ILPC_Contact_Preference__c,
                                                                                                        OOHC_First_Name__c, OOHC_Last_Name__c, OOHC_Email__c, OOHC_Phone__c, OOHC_Mobile__c, OOHC_Contact_Preference__c,
                                                                                                        SBQQ__Quote__c, Opportunity_Owner_Id__c
                                                                                                FROM SBQQ__QuoteDocument__c]);
        List<SBQQ__QuoteDocument__c> newQuoteDocuments = quoteDocumentsMap.values().deepClone(true);
        for ( SBQQ__QuoteDocument__c theDocument : newQuoteDocuments ) {
            theDocument.LC_First_Name__c = 'Test new';
            theDocument.LC_Last_Name__c = 'Contact';
            theDocument.LC_Email__c = 'test@email.com';
            theDocument.BC_First_Name__c = 'Test new';
            theDocument.BC_Last_Name__c = 'Contact';
            theDocument.BC_Email__c = 'test@email.com';
        }
        SBQQ_QuoteDocumentService theDocumentService = new SBQQ_QuoteDocumentService();
        Map<SBQQ__QuoteDocument__c, Set<String>> updatedDocumentsMap = theDocumentService.getDocumentsWithUpdatedContactInfo(quoteDocumentsMap, newQuoteDocuments);

        //when
        Test.startTest();
        PotentialContactService thePotentialContactService = new PotentialContactService();
        thePotentialContactService.createPotentialContactsForUpdatedDocuments(updatedDocumentsMap, quoteDocumentsMap);

        //then
        List<Potential_Contact__c> potentialContacts = [SELECT First_Name__c, Last_Name__c, New_First_Name__c, New_Last_Name__c
                                                        FROM Potential_Contact__c];
        System.assertNotEquals(true, potentialContacts.isEmpty());
        System.assertEquals(1, potentialContacts.size());
        Test.stopTest();
    }
}