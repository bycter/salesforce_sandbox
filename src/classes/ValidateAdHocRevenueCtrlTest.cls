@isTest
public class ValidateAdHocRevenueCtrlTest {

    @isTest
    static void testIsTaxCodeFound() {
        String testTaxCode = 'testTaxCode';
        RecordDmlTest.createTaxCode(testTaxCode);
        System.assertEquals(true, ValidateAdHocRevenueCtrl.isTaxCodeFound(testTaxCode));
    }

    @isTest
    static void testIsNotFoundTaxCode() {
        String testTaxCode = 'testTaxCode';
        System.assertEquals(false, ValidateAdHocRevenueCtrl.isTaxCodeFound(testTaxCode));
    }

    @isTest
    static void testIsCompanyFound() {
        String testCompany = 'testCompany';
        RecordDmlTest.createCompany(testCompany);
        System.assertEquals(true, ValidateAdHocRevenueCtrl.isCompanyFound(testCompany));
    }

    @isTest
    static void testIsNotFoundCompany() {
        String testCompany = 'testCompany';
        System.assertEquals(false, ValidateAdHocRevenueCtrl.isCompanyFound(testCompany));
    }

    @isTest
    static void testValuesNotFound() {
        RecordDmlTest.createProducts();
        Product2 suiteProduct = [SELECT Id FROM Product2 WHERE Family = 'suite' AND ProductCode = 'OfficeRent' LIMIT 1];

        c2g__codaTaxCode__c taxCode = RecordDmlTest.createTaxCode(CreateAdHocRecordsController.TAX_CODE_NAME);
        c2g__codaCompany__c company = RecordDmlTest.createCompany(CreateAdHocRecordsController.COMPANY_NAME);
        Property__c prop = RecordDmlTest.createProperty();

        Account testAccount = RecordDmlTest.createAccount();

        List<Ad_hoc_Revenue__c> revenues = RecordDmlTest.createAdHocRevenues(testAccount, taxCode, prop, company, suiteProduct);
        insert revenues;

        company.Name = 'New Name';
        update company;

        Test.startTest();
        try {
            ValidateAdHocRevenueCtrl.validateFields(revenues.get(0).Id);
            System.assert(false, 'the exception was not thrown out');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().containsIgnoreCase(ValidateAdHocRevenueCtrl.VALUES_NOT_FOUND_ERROR_MSG));
        }
        Test.stopTest();
    }

    @isTest
    static void testRecordNotFound() {
        String adHocId = Schema.SObjectType.Ad_hoc_Revenue__c.getSObjectType().getDescribe().getKeyPrefix() + '0'.repeat(11) + '1';
        Test.startTest();
        try {
            ValidateAdHocRevenueCtrl.validateFields(adHocId);
            System.assert(false, 'the exception was not thrown out');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().containsIgnoreCase(ValidateAdHocRevenueCtrl.RECORD_NOT_FOUND_ERROR_MSG));
        }
        Test.stopTest();
    }

}