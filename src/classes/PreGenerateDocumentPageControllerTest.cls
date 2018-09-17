@isTest
public class PreGenerateDocumentPageControllerTest {
    @isTest
    static void testDocumentGenerationForServicedQuote() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        PreGenerateDocumentPageController documentController = new PreGenerateDocumentPageController(sc);
        documentController.sendFor = 'signature';

        //when
        documentController.goToGenerateDocumentPage();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created');
    }

    @isTest
    static void testDocumentGenerationForVirtualQuote() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.generateVirtualQuoteWithLines();
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        PreGenerateDocumentPageController documentController = new PreGenerateDocumentPageController(sc);
        documentController.sendFor = 'signature';

        //when
        documentController.goToGenerateDocumentPage();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :VirtualQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created');
    }

    @isTest
    static void testDocumentGenerationReviewForServicedQuote() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        PreGenerateDocumentPageController documentController = new PreGenerateDocumentPageController(sc);
        documentController.sendFor = 'review';

        //when
        documentController.goToGenerateDocumentPage();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created');
    }

    @isTest
    static void testDocumentGenerationReviewForVirtualQuote() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.generateVirtualQuoteWithLines();
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        PreGenerateDocumentPageController documentController = new PreGenerateDocumentPageController(sc);
        documentController.sendFor = 'review';

        //when
        documentController.goToGenerateDocumentPage();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :VirtualQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created');
    }

    @isTest
    static void testDocumentGenerationForConvQuote() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        PreGenerateDocumentPageController documentController = new PreGenerateDocumentPageController(sc);
        documentController.sendFor = 'signature';

        //when
        documentController.goToGenerateDocumentPage();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ConventionalQuoteDocumentGenerator.PRICING_DOCUMENT_NAME], 'Pricing document has not been created');
    }

    @isTest
    static void testDocumentGenerationReviewForConvQuote() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
        ApexPages.StandardController sc = new ApexPages.StandardController(quote);
        PreGenerateDocumentPageController documentController = new PreGenerateDocumentPageController(sc);
        documentController.sendFor = 'review';

        //when
        documentController.goToGenerateDocumentPage();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ConventionalQuoteDocumentGenerator.PRICING_DOCUMENT_NAME], 'Pricing document has not been created');
    }
}