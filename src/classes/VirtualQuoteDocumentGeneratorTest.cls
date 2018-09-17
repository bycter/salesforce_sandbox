@isTest
public with sharing class VirtualQuoteDocumentGeneratorTest {
    @testSetup
    public static void initData() {

        Property__c property = RecordDmlTest.createProperty();

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
                SBQQ__Status__c = 'Draft',
                Property__c = property.id);
        insert quote;
    }

    @isTest
    static void additionalDocemtentsShouldBeGenerated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new VirtualQuoteDocumentGenerator();

        //when
        documentGenerator.updateAdditionalDocuments(quote);

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :VirtualQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c =: quote.Id AND Name =: VirtualQuoteDocumentGenerator.LICENCE_AGREEMENT_DOCUMENT_NAME], 'Licence Agreement document has not been created');
    }

    @isTest
    static void additionalDocemtentsShouldBeUpdated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new VirtualQuoteDocumentGenerator();

        //when
        documentGenerator.updateAdditionalDocuments(quote);
        //Doesn't create a new documents, the previous document versions should be updated
        documentGenerator.updateAdditionalDocuments(quote);

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :VirtualQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created or has been created twice');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c =: quote.Id AND Name =: VirtualQuoteDocumentGenerator.LICENCE_AGREEMENT_DOCUMENT_NAME], 'Licence Agreement document has not been created or has been created twice');
    }
}