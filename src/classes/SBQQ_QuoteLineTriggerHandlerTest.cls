@IsTest
public class SBQQ_QuoteLineTriggerHandlerTest {
    @IsTest
    static void testPropertyPopulatedFromQuote() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Property_for_Filter__c, SBQQ__Quote__r.Property__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            System.assertEquals(quoteLine.SBQQ__Quote__r.Property__c, quoteLine.Property_for_Filter__c);
        }
    }

    @IsTest
    static void testQuantaPopulatedFromProduct() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);

        List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, Quanta__c, SBQQ__ProductCode__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id];

        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            System.assertNotEquals(null, quoteLine.Quanta__c);
            if (quoteLine.SBQQ__ProductCode__c == 'OfficeRent') {
                System.assertEquals('Office', quoteLine.Quanta__c);
            }
        }
    }
}