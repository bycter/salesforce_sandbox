/**
 * @description Test class for SpringCMGenerateContractBtnController class
 */
@isTest
public class SpringCMGenerateContractBtnControllerTst {
    @testSetup
    public static void setupData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
    }

    @isTest
    public static void testButton() {
        Test.startTest();
        SBQQ__Quote__c updateQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        updateQuote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
        update updateQuote;
        Case ltCase = [
                SELECT CaseNumber, Account.Name, Opportunity__r.Name, Quote__r.Name
                FROM Case
                WHERE RecordTypeId = :RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.LEASE_TRANSACTION_RECORD_TYPE)
                LIMIT 1
        ];
        ApexPages.StandardController stdController = new ApexPages.StandardController(ltCase);
        SpringCMGenerateContractBtnController btnContoller = new SpringCMGenerateContractBtnController(stdController);
        PageReference pageRef = btnContoller.redirectToSpringCM();
        System.assertNotEquals(null, pageRef);
        System.assertEquals(true, pageRef.getUrl().contains(ltCase.Id));
    }
}