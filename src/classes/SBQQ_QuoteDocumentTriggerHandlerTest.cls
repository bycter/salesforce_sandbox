/**
 * @description Test class for SBQQ_QuoteDocumentTriggerHandler
 */
@isTest
private class SBQQ_QuoteDocumentTriggerHandlerTest {

    @testSetup
    public static void setupData() {
        //given
        Test.startTest();
        Account testAccount = RecordDmlTest.createAccount(false);
        testAccount.Company_Registration_Number__c = '123';
        insert testAccount;

        List<Contact> testContacts = new List<Contact> {
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_LC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_ILPC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_OOHC),
            RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_BC)
        };
        insert testContacts;

        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
        quote.SBQQ__Account__c = testAccount.Id;
        update quote;

        SBQQ__QuoteTemplate__c template = new SBQQ__QuoteTemplate__c(
                Name = 'Test',
                Update_Quote_Status__c = true);
        insert template;
        Test.stopTest();
    }

    @isTest
    private static void testPopulationOfMergefields() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        //when
        Test.startTest();
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = quote.Id
        );
        insert quoteDocument;
        quoteDocument = [SELECT LC_First_Name__c, BC_Last_Name__c, ILPC_Email__c, OOHC_First_Name__c,
                                SBQQ__Quote__c, Company_Registration_Number__c
                        FROM SBQQ__QuoteDocument__c
                        WHERE Id = :quoteDocument.Id];
        //then
        System.assertNotEquals(null, quoteDocument.LC_First_Name__c);
        System.assertNotEquals(null, quoteDocument.BC_Last_Name__c);
        System.assertNotEquals(null, quoteDocument.ILPC_Email__c);
        System.assertNotEquals(null, quoteDocument.OOHC_First_Name__c);
        System.assertEquals('123', quoteDocument.Company_Registration_Number__c);
        Test.stopTest();
    }

    @isTest
    private static void testQuoteDocumentUpdate() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = quote.Id
        );
        insert quoteDocument;

        //when
        Test.startTest();
        quoteDocument = [SELECT LC_First_Name__c, BC_Last_Name__c, ILPC_Email__c, OOHC_First_Name__c,
                                SBQQ__Quote__c, Company_Registration_Number__c, Account_Id__c
                        FROM SBQQ__QuoteDocument__c
                        WHERE Id = :quoteDocument.Id];
        quoteDocument.LC_First_Name__c = 'Test new';
        quoteDocument.LC_Last_Name__c = 'Contact';
        quoteDocument.BC_Email__c = 'test@test.com';
        quoteDocument.BC_Phone__c = '987654321';
        quoteDocument.Company_Registration_Number__c = '456';
        update quoteDocument;

        //then
        List<Potential_Contact__c> potentialContacts = [SELECT First_Name__c, Last_Name__c, New_First_Name__c, New_Last_Name__c
                                                        FROM Potential_Contact__c];
        System.assertNotEquals(true, potentialContacts.isEmpty());
        System.assertEquals('456', [SELECT Company_Registration_Number__c FROM Account WHERE Id = :quoteDocument.Account_Id__c].Company_Registration_Number__c);
        Test.stopTest();
    }

    @isTest
    private static void testQuoteAcceptanceWhenSignedByCD() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Contact companyDirector = RecordDmlTest.createContact(testAccount.Id, SBQQ_QuoteConstants.CONTACT_TYPE_CD);
        companyDirector.FirstName = 'Company';
        companyDirector.LastName = 'Director';
        insert companyDirector;

        SBQQ__Quote__c quote = [SELECT SBQQ__PrimaryContact__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTemplate__c template = [SELECT Id FROM SBQQ__QuoteTemplate__c LIMIT 1];
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = quote.Id,
            SBQQ__QuoteTemplate__c = template.Id,
            Signature_Status__c = 'Sent'
        );
        insert quoteDocument;

        Inventory__c inventory = [SELECT Id FROM Inventory__c LIMIT 1];
        Id designCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Design').getRecordTypeId();
        Case designCase = new Case(
                RecordTypeId = designCaseRecordTypeId,
                Inventory__c = inventory.Id,
                ContactId = quote.SBQQ__PrimaryContact__c,
                Customer_Budget__c = 1000
        );
        insert designCase;

        //when
        Test.startTest();
        quoteDocument.SBQQ__ElectronicSignature__c = false;
        quoteDocument.Signature_Status__c = SBQQ_QuoteConstants.STATUS_SIGNATURE_COMPLETE;
        quoteDocument.SBQQDS__EnvelopeId__c = 'testEnvelopeId1';
        quoteDocument.CD_First_Name__c = 'Company';
        quoteDocument.CD_Last_Name__c = 'Director 2';
        //Can't make the testing as Docusing tries to send something from the packaged code.
        // update quoteDocument;

        //then
        // quoteDocument = [SELECT Signed_By_CD__c FROM SBQQ__QuoteDocument__c WHERE Id =:quoteDocument.Id];
        // System.assertEquals(false, quoteDocument.Signed_By_CD__c);
        // System.assertEquals(1, [SELECT count() FROM Task WHERE System_Code__c = :TaskService.SETUP_CD_SYSTEM_CODE]);
        Test.stopTest();
    }

    @isTest
    private static void testmoveDirectDebitFormFieldsToSecureObject() {
        //given
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
            SBQQ__Quote__c = quote.Id
        );
        insert quoteDocument;

        //when
        Test.startTest();
        quoteDocument.DDF_Acc_Num_1__c = '1';
        quoteDocument.DDF_Branch_Sort_Code_6__c = '1';
        quoteDocument.DDF_Signer_Name__c = 'Test Signer';
        quoteDocument.Signature_Status__c = SBQQ_QuoteConstants.STATUS_SIGNATURE_COMPLETE;
        //Can't make the testing as Docusing tries to send something from the packaged code.
        // update quoteDocument;

        // Customer_Confidential_Documentation__c secureRecord = [SELECT Acc_Num_1__c, Branch_Sort_Code_6__c, Signer_Name__c, Account__c
        //                                                        FROM Customer_Confidential_Documentation__c
        //                                                        WHERE SBQQ_Quote_Document__c = :quoteDocument.Id];
        // System.assertNotEquals(null, secureRecord);
        // System.assertNotEquals(null, secureRecord.Account__c);
        // System.assertEquals(quoteDocument.DDF_Acc_Num_1__c, secureRecord.Acc_Num_1__c);
        // System.assertEquals(quoteDocument.DDF_Branch_Sort_Code_6__c, secureRecord.Branch_Sort_Code_6__c);
        // System.assertEquals(quoteDocument.DDF_Signer_Name__c, secureRecord.Signer_Name__c);
        Test.stopTest();
    }

    @isTest
    static void givenQuote_whenDocumentCreated_thenQuoteStatusIsPresented() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteTemplate__c quoteTemplate = [SELECT Id FROM SBQQ__QuoteTemplate__c LIMIT 1];
        System.assertEquals('Draft', quote.SBQQ__Status__c);

        //when
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
                SBQQ__Quote__c = quote.Id,
                SBQQ__ElectronicSignature__c = true,
                SBQQ__QuoteTemplate__c = quoteTemplate.Id);
        insert quoteDocument;

        //then
        quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals('Presented', quote.SBQQ__Status__c);
    }
}