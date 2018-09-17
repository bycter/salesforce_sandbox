/**
 * @description Test class for AccountService
 */
@isTest
private class AccountServiceTest {

    @testSetup
    public static void setupData() {
        Account testAccount = RecordDmlTest.createQuniqueAccount(false);
        Account testAccount2 = RecordDmlTest.createQuniqueAccount(false);
        Account testAccount3 = RecordDmlTest.createQuniqueAccount(false);
        testAccount.Company_Registration_Number__c = '123';
        testAccount2.Company_Registration_Number__c = '234';
        testAccount3.Company_Registration_Number__c = '345';
        insert new List<Account>{testAccount, testAccount2, testAccount3};
    }

    @isTest
    private static void testUpdateCompanyRegistrationNumbers() {
        //given
        List<Account> testAccounts = [SELECT Company_Registration_Number__c FROM Account ORDER BY Id];
        Map<Id, String> accountIdToCompanyNumberMap = new Map<Id, String>{
            testAccounts[0].Id => '111',
            testAccounts[1].Id => '222'
        };
        AccountService theAccountService = new AccountService();

        Test.startTest();
        //when
        theAccountService.updateCompanyRegistrationNumbers(accountIdToCompanyNumberMap);

        //then
        List<Account> updatedAccounts = [SELECT Company_Registration_Number__c FROM Account ORDER BY Id];
        System.assertEquals('111', updatedAccounts[0].Company_Registration_Number__c);
        System.assertEquals('222', updatedAccounts[1].Company_Registration_Number__c);
        System.assertEquals('345', updatedAccounts[2].Company_Registration_Number__c);
        Test.stopTest();
    }
}