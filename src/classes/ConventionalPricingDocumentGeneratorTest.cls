@isTest
public class ConventionalPricingDocumentGeneratorTest {

    @testSetup
    public static void initData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
    }

    @isTest
    static void givenSBQQ_Quote_whenDocumentGeneratorInstanceCreated_thenQuoteLineItemsShouldBeLoadedIntoDocumentGenerator() {
        //given
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
    
    //when
        ApexPages.currentPage().getParameters().put('id', String.valueOf(quote.Id));
        ConventionalPricingDocumentGenerator documentGenerator = new ConventionalPricingDocumentGenerator();

        //then
        System.assert(documentGenerator.lineItems.size() > 0, 'Quote Line items have not been loaded');
    }
}