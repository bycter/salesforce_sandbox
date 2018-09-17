@isTest
public class QuoteButtonsControllerTest {
    @isTest 
    static void testQuotePageLinks() {
        //given
    SBQQ__Quote__c quote = RecordDmlTest.createCPQQuote();
        ApexPages.StandardController standardController = new ApexPages.StandardController(quote);
        QuoteButtonsController customController = new QuoteButtonsController(standardController);

        PageReference generateDocumentPage = customController.generateDocument();
        PageReference includeDocumentPage = customController.includeDocument();
        PageReference previewDocumentPage = customController.previewDocument();
        PageReference unlockQuotePage = customController.unlockQuote();

        //then
        System.assertNotEquals(null, generateDocumentPage, 'Generate Document Page link is not correct');
        System.assertNotEquals(null, includeDocumentPage, 'Include Document Page link is not correct');
        System.assertNotEquals(null, previewDocumentPage, 'Preview Document Page link is not correct');
        System.assertEquals(null, unlockQuotePage, 'Unlock Quote Page link is not correct');
    }
}