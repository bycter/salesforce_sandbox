@isTest
public class ConventionalQuoteDocumentGeneratorTest {

    @testSetup
    public static void initData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
    }

    @isTest
    static void givenSBQQ_QuoteAndDocumentGenerator_whenAdditionalDocumentsUpdated_thenPricingAndTermsDocumentShouldBeGenerated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new ConventionalQuoteDocumentGenerator();

        //when
        documentGenerator.updateAdditionalDocuments(quote);

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ConventionalQuoteDocumentGenerator.PRICING_DOCUMENT_NAME], 'Pricing document has not been created');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ConventionalQuoteDocumentGenerator.TERMS_DOCUMENT_NAME], 'Terms document has not been created');
    }

    @isTest
    static void givenSBQQ_QuoteAndDocumentGenerator_whenAdditionalDocumentsUpdatedSecondTime_thenPricingAndTermsDocumentShouldBeUpdatedWithNewVersions() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new ConventionalQuoteDocumentGenerator();

        //when
        documentGenerator.updateAdditionalDocuments(quote);
        //Doesn't create a new documents, the previous document versions should be updated
        documentGenerator.updateAdditionalDocuments(quote);

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ConventionalQuoteDocumentGenerator.PRICING_DOCUMENT_NAME], 'Pricing document has not been created or has been created twice');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ConventionalQuoteDocumentGenerator.TERMS_DOCUMENT_NAME], 'Terms document has not been created or has been created twice');
    }
}