public class PreGenerateDocumentPageController extends QuoteDocumentParams {

    public SBQQ__Quote__c quote { get; set; }
    private QuoteDocumentGenerator documentGenerator { get; set; }
    private ApexPages.StandardController stdController { get; set; }

    private Quote_Template_Settings__c templateSettings = Quote_Template_Settings__c.getOrgDefaults();

    public String sendFor { get; set; }
    public Boolean isOfflineDocumentAdded { get; set; }
    public Boolean isVirtualQuote { get; set; }

    public PreGenerateDocumentPageController(ApexPages.StandardController stdController) {
        this.stdController = stdController;
        quote = (SBQQ__Quote__c) stdController.getRecord();
        quote = [
                SELECT Id, SBQQ__QuoteTemplateId__c, RecordTypeId, RecordType.DeveloperName,
                        Property__c, Pay_by_BACs__c, Pay_by_BACs_Approved__c, (SELECT Id FROM SBQQ__LineItems__r)
                FROM SBQQ__Quote__c
                WHERE Id = :quote.Id
        ];
        loadDocumentGenerator(quote.RecordType.DeveloperName);
        isOfflineDocumentAdded = isOfflineDocumentAdded(quote);
        isVirtualQuote = quote.RecordType.DeveloperName == SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE
                || quote.RecordType.DeveloperName == SBQQ_QuoteConstants.VIRTUAL_LOCKED_RECORD_TYPE;
    }

    public PageReference redirectToQuote() {
        PageReference redirect = new PageReference('/' + quote.Id);
        redirect.setRedirect(true);
        return redirect;
    }

    public PageReference goToGenerateDocumentPage() {
        PageReference redirect;
        updateQuoteTemplate(quote.RecordType.DeveloperName);
        updateAdditionalDocuments();
        if (sendFor == GENERATE_OFFLINE_DOCUMENT) {
            update new SBQQ__Quote__c(Id = quote.Id, SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_PENDING_APPROVAL_OFFLINE_EDIT);
            redirect = new PageReference('/apex/GenerateOfflineDocument?id=' + quote.Id);
        } else {
            redirect = new PageReference('/apex/SBQQ__GenerateDocument?id=' + quote.Id);
        }
        redirect.setRedirect(true);
        return redirect;
    }

    public void updateAdditionalDocuments() {
        Map<String, String> sendingOptions = new Map<String, String>();
        if (sendFor == SEND_OFFLINE_DOCUMENT || sendFor == GENERATE_OFFLINE_DOCUMENT) {
            sendingOptions.put(SEND_FOR_KEY_NAME, SIGNATURE);
            sendingOptions.put(SEND_OFFLINE_DOCUMENT, SEND_OFFLINE_DOCUMENT);
        } else {
            sendingOptions.put(SEND_FOR_KEY_NAME, sendFor);
        }
        documentGenerator.updateAdditionalDocuments(quote, sendingOptions);
    }

    private void loadDocumentGenerator(String recordTypeName) {
        if (recordTypeName.contains('Serviced')) {
            documentGenerator = new ServicedQuoteDocumentGenerator();
        } else if (recordTypeName.contains('Conventional')) {
            documentGenerator = new ConventionalQuoteDocumentGenerator();
        } else if (recordTypeName.contains('Virtual')) {
            documentGenerator = new VirtualQuoteDocumentGenerator();
        }
    }

    private void updateQuoteTemplate(String recordTypeName) {
        SBQQ__QuoteTemplate__c template;
        //Sending of offline documents should be done in frame of signature process
        if (!String.isBlank(sendFor)) {
            if (recordTypeName.contains('Serviced')) {
                if (sendFor == SIGNATURE || sendFor == SEND_OFFLINE_DOCUMENT) {
                    template = getTemplateById(templateSettings.Serviced_Signature_TemplateId__c);
                } else {
                    template = getTemplateById(templateSettings.Serviced_Review_TemplateId__c);
                }
            } else if (recordTypeName.contains('Conventional')) {
                if (sendFor == SIGNATURE || sendFor == SEND_OFFLINE_DOCUMENT) {
                    template = getTemplateById(templateSettings.Conventional_Signature_TemplateId__c);
                } else {
                    template = getTemplateById(templateSettings.Conventional_Review_TemplateId__c);
                }
            } else if (recordTypeName.contains('Virtual')) {
                if (sendFor == SIGNATURE || sendFor == SEND_OFFLINE_DOCUMENT) {
                    template = getTemplateById(templateSettings.Virtual_Signature_TemplateId__c);
                } else {
                    template = getTemplateById(templateSettings.Virtual_Review_TemplateId__c);
                }
            }
        }
        quote.SBQQ__QuoteTemplateId__c = template != null ? template.Id : null;
        update quote;
    }

    public static Boolean isOfflineDocumentAdded(SBQQ__Quote__c quote) {
        List<SBQQ__RelatedContent__c> additionalDocuments = [SELECT Id FROM SBQQ__RelatedContent__c WHERE SBQQ__Quote__c = :quote.Id AND Manual_Upload__c = true LIMIT 1];
        return additionalDocuments.size() == 1;
    }

    private SBQQ__QuoteTemplate__c getTemplateById(String templateId) {
        List<SBQQ__QuoteTemplate__c> templates = [SELECT Id FROM SBQQ__QuoteTemplate__c WHERE Id = :templateId LIMIT 1];
        if (!templates.isEmpty()) {
            return templates.get(0);
        }
        return null;
    }
}