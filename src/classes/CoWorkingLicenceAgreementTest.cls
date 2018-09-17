@isTest
public class CoWorkingLicenceAgreementTest {
    @testSetup
    public static void initData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();
    }

    @isTest
    static void givenSBQQ_Quote_whenDocumentGeneratorInstanceCreated_thenQuoteLineItemsShouldBeLoadedIntoDocumentGenerator() {
        //given
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        //when
        ApexPages.currentPage().getParameters().put('id', String.valueOf(quote.Id));
        CoWorkingLicenceAgreement documentGenerator = new CoWorkingLicenceAgreement();

        //then
        System.assert(documentGenerator.mapProducts.size() > 0, 'Products have not been loaded');
    }
}