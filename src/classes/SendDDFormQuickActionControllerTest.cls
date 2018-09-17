/**
 * @description Test class fro SendDDFormQuickActionController class
 */
@isTest
public class SendDDFormQuickActionControllerTest {

    @testSetup
    public static void setupData() {
        RecordDmlTest.createDocusignSettings();
        RecordDmlTest.createContact();
        RecordDmlTest.createProperty();
        c2g__codaCompany__c testCompany = [SELECT Id FROM c2g__codaCompany__c LIMIT 1];
        Account testAccount = RecordDmlTest.createAccount();
        Customer_Confidential_Documentation__c ddForm = new Customer_Confidential_Documentation__c(
                Account__c = testAccount.Id,
                Name_Of_Account_Holder__c = 'Test Account',
                Branch_Sort_Code__c = '123456',
                Legal_Entity__c = testCompany.Id,
                Collections_File_Sequence_Number__c = CustomerConfidentialDocumentationService.DEFAULT_VALUE_FOR_COLLECTIONS_FILE_SEQUENCE_NUMBER
        );
        insert ddForm;
    }

    @isTest
    public static void testSendDDForm() {
        Contact testContact = [SELECT Name, Email FROM Contact LIMIT 1];
        Customer_Confidential_Documentation__c ddForm = [SELECT Account__c FROM Customer_Confidential_Documentation__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpDocuSignResponseGenerator());
        Test.startTest();
        SendDDFormQuickActionController.sendDDForm(ddForm.Id, testContact.Id, ddForm.Account__c, 'some text body');
        ddForm.Signature_Status__c = 'Completed';
        ddForm.DDF_Acc_Num_1__c = '1';
        ddForm.DDF_Acc_Num_2__c = '2';
        ddForm.DDF_Acc_Num_3__c = '3';
        ddForm.DDF_Acc_Num_4__c = '4';
        ddForm.DDF_Acc_Num_5__c = '5';
        ddForm.DDF_Acc_Num_6__c = '6';
        ddForm.DDF_Acc_Num_7__c = '7';
        ddForm.DDF_Acc_Num_8__c = '8';
        update ddForm;
        ddForm = [SELECT Bank_Building_Society_Account_Number__c, Date_Signed__c FROM Customer_Confidential_Documentation__c LIMIT 1];
        System.assertEquals('12345678', ddForm.Bank_Building_Society_Account_Number__c);
        System.assertEquals(Date.today(), ddForm.Date_Signed__c);
        Test.stopTest();
    }
}