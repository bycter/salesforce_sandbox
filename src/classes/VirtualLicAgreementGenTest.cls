@isTest
public with sharing class VirtualLicAgreementGenTest {
    @isTest static void generateVirtualTermDocument() {

        SBQQ__Quote__c quote = RecordDmlTest.generateVirtualQuoteWithLines();

        Test.StartTest();
        ApexPages.currentPage().getParameters().put('id', quote.Id);
        VirtualLicAgreementGenerator testTermDoc1 = new VirtualLicAgreementGenerator();
        testTermDoc1.init();
        ApexPages.currentPage().getParameters().put('id', String.valueOf(quote.Id));
        VirtualLicAgreementGenerator testTermDoc = new VirtualLicAgreementGenerator();
        testTermDoc.init();
        System.assertEquals(6, testTermDoc.qliList.size());
        Test.StopTest();
    }
}