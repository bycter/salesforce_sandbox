@isTest
public with sharing class ServicedPricingDocumentGeneratorTest {

    @isTest static void generateServicedTermDocument() {

        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();

        Test.StartTest();
        ApexPages.currentPage().getParameters().put('id', '');
        ServicedPricingDocumentGenerator testTermDoc1 = new ServicedPricingDocumentGenerator();
        testTermDoc1.init();
        ApexPages.currentPage().getParameters().put('id', String.valueOf(quote.Id));
        ServicedPricingDocumentGenerator testTermDoc = new ServicedPricingDocumentGenerator();
        testTermDoc.init();
        System.assertEquals(3, testTermDoc.getAdditionalProducts().size());
        Test.StopTest();
    }
}