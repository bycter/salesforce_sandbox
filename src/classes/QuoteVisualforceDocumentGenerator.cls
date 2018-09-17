public virtual class QuoteVisualforceDocumentGenerator {

    public void generateNewDocumentVersion(SBQQ__Quote__c quote, PageReference pdfTemplate, String documentName) {
        generateNewDocumentVersion(quote, pdfTemplate, documentName, new Map<String, String>());
    }

    public void generateNewDocumentVersion(SBQQ__Quote__c quote, PageReference pdfTemplate, String documentName, Integer order) {
        generateNewDocumentVersion(quote, pdfTemplate, documentName, new Map<String, String>(), order);
    }

    public void generateNewDocumentVersion(SBQQ__Quote__c quote, PageReference pdfTemplate, String documentName, Map<String, String> params) {
        generateNewDocumentVersion(quote, pdfTemplate, documentName, params, false);
    }

    public void generateNewDocumentVersion(SBQQ__Quote__c quote, PageReference pdfTemplate, String documentName, Map<String, String> params, Boolean required) {
        generateNewDocumentVersion(quote, pdfTemplate, documentName, params, 0, required);
    }

    public void generateNewDocumentVersion(SBQQ__Quote__c quote, PageReference pdfTemplate, String documentName, Map<String, String> params, Integer order) {
        generateNewDocumentVersion(quote, pdfTemplate, documentName, params, order, false);
    }

    public void generateNewDocumentVersion(SBQQ__Quote__c quote, PageReference pdfTemplate, String documentName, Map<String, String> params, Integer order, Boolean required) {
        pdfTemplate.getParameters().put('id', quote.Id);
        pdfTemplate.getParameters().putAll(params);
        Attachment attach = new Attachment(parentId = quote.Id, name = documentName + '.pdf', body = getContent(pdfTemplate));
        insert attach;
        SBQQ__RelatedContent__c quoteDocument;
        quoteDocument = new SBQQ__RelatedContent__c(Name = documentName, SBQQ__ExternalId__c = attach.Id, SBQQ__Quote__c = quote.Id, SBQQ__DisplayOrder__c = order, SBQQ__Required__c = required, Manual_Upload__c = false);
        insert quoteDocument;
    }


    private Blob getContent(PageReference pdfTemplate) {
        Blob templateContent;
        // getContent() method isn't supported over tests
        if (!Test.IsRunningTest()) {
            templateContent = pdfTemplate.getContent();
        } else {
            templateContent = Blob.valueOf('Unit Test');
        }
        return templateContent;
    }
}