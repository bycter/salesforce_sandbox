@IsTest
private class AttachmentTriggerHandlerTest {

    @testSetup
    public static void initData() {
        Property__c property = new Property__c(Name = 'Test property', Region__c = 'Manchester City Centre',
                Street__c = 'Test');
        insert property;

        Inventory__c inventory = new Inventory__c(Name = 'Test', Property__c = property.Id, Sales_Status__c = 'Available');
        insert inventory;

        SBQQ__Quote__c quote = RecordDmlTest.createCPQQuote();

        Contract contract = RecordDmlTest.createContract(quote, property);

        quote.Contract__c = contract.Id;
        quote.RecordTypeId = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get('Serviced').getRecordTypeId();
        update quote;

        SBQQ__QuoteTemplate__c quoteTemplate = new SBQQ__QuoteTemplate__c(Name = 'Test Template', SBQQ__DeploymentStatus__c = 'In Development',
                CurrencyIsoCode = 'GBP', SBQQ__PageWidth__c = 8.50, SBQQ__PageHeight__c = 11.00, SBQQ__TopMargin__c = 0.50,
                SBQQ__BottomMargin__c = 0.50, SBQQ__LeftMargin__c = 0.50, SBQQ__RightMargin__c = 0.50,
                SBQQ__FontFamily__c = 'Helvetica', SBQQ__FontSize__c = 9.0, SBQQ__ShadingColor__c = 'FFFFFF',
                SBQQ__BorderColor__c = '000000', Update_Quote_Status__c = true);
        insert quoteTemplate;

        SBQQ__QuoteDocument__c quoteDocument = new SBQQ__QuoteDocument__c(Name = 'Test Quote Document', SBQQ__Quote__c = quote.Id,
                SBQQ__Version__c = 1, CurrencyIsoCode = 'GBP', SBQQ__SignatureStatus__c = 'Completed', SBQQ__QuoteTemplate__c = quoteTemplate.Id);
        insert quoteDocument;

        Blob bodyBlob = Blob.valueOf('Test Attachment Body');

        Attachment attachment = new Attachment(Name = 'Unit Test Attachment', Body = bodyBlob, ParentId = quoteDocument.Id);
        insert attachment;
    }

    @isTest
    public static void checkAttachmentOnContract() {
        Contract entityContract = [SELECT Id FROM Contract LIMIT 1];
        List<Attachment> entityAttachments = [SELECT Id, Name FROM Attachment WHERE ParentId = :entityContract.Id];
        System.assertEquals(1, entityAttachments.size());
    }
}