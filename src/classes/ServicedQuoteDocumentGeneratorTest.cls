@isTest
public class ServicedQuoteDocumentGeneratorTest {

    @testSetup
    public static void initData() {
        Test.startTest();
        Document directDebitForm = new Document(
                Body = Blob.valueOf('Test Document'),
                ContentType = 'application/pdf',
                DeveloperName = 'Direct_Debit_1',
                IsPublic = true,
                Name = 'Direct Debit',
                FolderId = [SELECT Id FROM Folder WHERE DeveloperName = 'Quote_Documents'].id);
        insert directDebitForm;

        c2g__codaCompany__c ffCompany = new c2g__codaCompany__c(
                Direct_Debit_Form_Developer_Name__c = directDebitForm.DeveloperName);
        insert ffCompany;

        Property__c property = new Property__c(
                Name = 'Test Property',
                Region__c = 'Alderley Park',
		            Street__c = 'Test',
                Company__c = ffCompany.Id);
        insert property;

        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();
        quote.Property__c = property.id;
        update quote;
        Test.stopTest();
    }

    @isTest
    static void givenSBQQ_QuoteAndDocumentGenerator_whenAdditionalDocumentsUpdated_thenDirectDebitFormShouldBeGenerated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new ServicedQuoteDocumentGenerator();

        //when
        Test.startTest();
        documentGenerator.updateAdditionalDocuments(quote);
        Test.stopTest();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created');
    }

    @isTest
    static void givenSBQQ_QuoteAndDocumentGenerator_whenAdditionalDocumentsUpdated_thenPricingAndLicenceAgreementShouldBeGenerated() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new ServicedQuoteDocumentGenerator();

        //when
        Test.startTest();
        documentGenerator.updateAdditionalDocuments(quote);
        Test.stopTest();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.PRICING_DOCUMENT_NAME], 'Pricing Document has not been created');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.LICENCE_AGREEMENT_DOCUMENT_NAME], 'Licence Agreement document has not been created');
    }

    @isTest
    static void givenSBQQ_QuoteAndDocumentGenerator_whenAdditionalDocumentsUpdatedSecondTime_thenDirectDebitFormShouldBeUpdatedWithNewVersions() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new ServicedQuoteDocumentGenerator();

        //when
        Test.startTest();
        documentGenerator.updateAdditionalDocuments(quote);
        //Doesn't create a new documents, the previous document versions should be updated
        documentGenerator.updateAdditionalDocuments(quote);
        Test.stopTest();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.DIRECT_DEBIT_DOCUMENT_NAME], 'Direct Debit document has not been created or has been created twice');
    }

    @isTest
    static void givenSBQQ_QuoteAndDocumentGenerator_whenAdditionalDocumentsUpdatedSecondTime_thenPricingAndLicenceAgreementShouldBeUpdatedWithNewVersions() {
        //given
        SBQQ__Quote__c quote = [SELECT Id, Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c FROM SBQQ__Quote__c LIMIT 1];
        QuoteDocumentGenerator documentGenerator = new ServicedQuoteDocumentGenerator();

        //when
        Test.startTest();
        documentGenerator.updateAdditionalDocuments(quote);
        //Doesn't create a new documents, the previous document versions should be updated
        documentGenerator.updateAdditionalDocuments(quote);
        Test.stopTest();

        //then
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.PRICING_DOCUMENT_NAME], 'Pricing Document has not been created or has been created twice');
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Name = :ServicedQuoteDocumentGenerator.LICENCE_AGREEMENT_DOCUMENT_NAME], 'Licence Agreement document has not been created or has been created twice');
    }
}