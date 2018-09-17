/**
 * @description Test class for CustomerConfidentialDocumentationSrv
 */
@isTest
private class CustomerConfidentialDocumentationSrvTest {

    @testSetup
    public static void setupData() {
        //given
        Account testAccount = RecordDmlTest.createAccount();
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
        quote.SBQQ__Account__c = testAccount.Id;

        Test.startTest();
        SBQQ.TriggerControl.disable();
        update quote;
        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(
                SBQQ__Quote__c = quote.Id
        );
        insert quoteDocument;
        quoteDocument = [
                SELECT Account_Id__c, SBQQ__Quote__r.Property__r.Company__c
                FROM SBQQ__QuoteDocument__c
                LIMIT 1
        ];
        Id legalEntity = quoteDocument.SBQQ__Quote__r.Property__r.Company__c;
        List<Customer_Confidential_Documentation__c> cdds = new List<Customer_Confidential_Documentation__c>();
        cdds.add(new Customer_Confidential_Documentation__c(
                Account__c = testAccount.Id,
                Legal_Entity__c = legalEntity,
                Collections_File_Sequence_Number__c = CustomerConfidentialDocumentationService.DEFAULT_VALUE_FOR_COLLECTIONS_FILE_SEQUENCE_NUMBER,
                Master__c = true
        ));
        cdds.add(new Customer_Confidential_Documentation__c(
                Account__c = testAccount.Id,
                Legal_Entity__c = legalEntity,
                Collections_File_Sequence_Number__c = CustomerConfidentialDocumentationService.DEFAULT_VALUE_FOR_COLLECTIONS_FILE_SEQUENCE_NUMBER
        ));
        insert cdds;
        Test.stopTest();
    }

    @isTest
    private static void testMoveDirectDebitFormFieldsToSecureObject() {
        SBQQ__QuoteDocument__c quoteDocument = [
                SELECT Account_Id__c, SBQQ__Quote__r.Property__r.Company__c
                FROM SBQQ__QuoteDocument__c
                LIMIT 1
        ];
        quoteDocument.DDF_Acc_Num_1__c = '1';
        quoteDocument.DDF_Branch_Sort_Code_6__c = '3';
        quoteDocument.DDF_Account_Name_1__c = 'Test';
        quoteDocument.DDF_Account_Name_2__c = 'Name';
        quoteDocument.DDF_Bank_Name__c = 'Bank';
        // quoteDocument.DDF_City__c = 'Manchester';
        quoteDocument.DDF_Reference__c = '12345';


        //when
        Test.startTest();
        CustomerConfidentialDocumentationService ccdService = new CustomerConfidentialDocumentationService();
        ccdService.moveDirectDebitFormFieldsToSecureObject(new List<SBQQ__QuoteDocument__c>{
                quoteDocument
        });
        Customer_Confidential_Documentation__c secureRecord = [
                SELECT Name_Of_Account_Holder__c, Bank_Building_Society_Account_Number__c, Branch_Sort_Code__c,
                        Name_and_Full_Postal_Address_Of_Bank__c, Reference__c, Date_Signed__c, Account__c,
                        Legal_Entity__c
                FROM Customer_Confidential_Documentation__c
                WHERE SBQQ_Quote_Document__c = :quoteDocument.Id
        ];
        System.assertNotEquals(null, secureRecord);
        System.assertNotEquals(null, secureRecord.Account__c);
        System.assertEquals('Test Name', secureRecord.Name_Of_Account_Holder__c);
        System.assertEquals('1', secureRecord.Bank_Building_Society_Account_Number__c);
        System.assertEquals('3', secureRecord.Branch_Sort_Code__c);
        System.assertEquals('Bank', secureRecord.Name_and_Full_Postal_Address_Of_Bank__c);
        System.assertEquals('12345', secureRecord.Reference__c);
        System.assertEquals(quoteDocument.SBQQ__Quote__r.Property__r.Company__c, secureRecord.Legal_Entity__c);
        Test.stopTest();
    }

    @IsTest
    private static void testCustomValidationCDD() {
        //when
        Test.startTest();
        try {
            Customer_Confidential_Documentation__c secureRecord = [
                    SELECT Id, Master__c
                    FROM Customer_Confidential_Documentation__c
                    WHERE Master__c = false
                    LIMIT 1
            ];
            secureRecord.Master__c = true;
            update secureRecord;
            System.assert(false, 'the exception was not thrown out');
        } catch (Exception e) {
            System.assertEquals(e.getMessage().contains(CustomerConfDocumentationTriggerHandler.ERROR_MSG_THERE_CAN_ONLY_BE_ONE_MASTER), true);
        }
        Test.stopTest();
    }

    @isTest
    private static void testAcknowledgementLetterGeneration() {
        SBQQ__QuoteDocument__c quoteDocument = [
            SELECT Account_Id__c, SBQQ__Quote__r.Property__r.Company__c
            FROM SBQQ__QuoteDocument__c
            LIMIT 1
        ];
        quoteDocument.DDF_Acc_Num_1__c = '1';
        quoteDocument.DDF_Branch_Sort_Code_6__c = '3';
        quoteDocument.DDF_Account_Name_1__c = 'Test';
        quoteDocument.DDF_Account_Name_2__c = 'Name';
        quoteDocument.DDF_Bank_Name__c = 'Bank';
        // quoteDocument.DDF_City__c = 'Manchester';
        quoteDocument.DDF_Reference__c = '12345';

        //when
        Test.startTest();
        new CustomerConfidentialDocumentationService().moveDirectDebitFormFieldsToSecureObject(new List<SBQQ__QuoteDocument__c>{
                quoteDocument
        });
        Customer_Confidential_Documentation__c secureRecord = [
                SELECT Name_Of_Account_Holder__c, Bank_Building_Society_Account_Number__c, Branch_Sort_Code__c,
                        Name_and_Full_Postal_Address_Of_Bank__c, Reference__c, Date_Signed__c, Account__c,
                        Legal_Entity__c
                FROM Customer_Confidential_Documentation__c
                WHERE SBQQ_Quote_Document__c = :quoteDocument.Id
        ];
        secureRecord.Send_Customer_Acknowledgement_Letter__c = true;
        update secureRecord;
        Test.stopTest();
        System.assertEquals(1, [SELECT COUNT() FROM Attachment WHERE ParentId =: secureRecord.Id]);
    }
}