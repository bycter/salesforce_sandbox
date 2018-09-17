public class QuoteButtonsController {

    public SBQQ__Quote__c quote { get; set; }

    public Boolean enableUnlockQuote { get; set; }
    public Boolean enableGenerateDocument { get; set; }
    public Boolean enableIncludeDocument { get; set; }
    public Boolean enablePreviewDocument { get; set; }
    public Boolean enableSubmitForOfflineEditApproval { get; set; }

    public Boolean refreshPage { get; set; }

    public QuoteButtonsController(ApexPages.StandardController controller) {
        quote = (SBQQ__Quote__c) controller.getRecord();
        quote = [
                SELECT Id, SBQQ__Status__c, OwnerId, RecordType.DeveloperName, Off_line_Edits__c
                FROM SBQQ__Quote__c
                WHERE Id = :quote.Id
        ];
        if (quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_APPROVED || quote.RecordType.DeveloperName == SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE) {
            enableGenerateDocument = true;
        }
        if (quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_PENDING_APPROVAL_OFFLINE_EDIT || quote.RecordType.DeveloperName == SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE) {
            enableIncludeDocument = true;
        }
        if (quote.SBQQ__Status__c != SBQQ_QuoteConstants.STATUS_DRAFT && quote.SBQQ__Status__c != SBQQ_QuoteConstants.STATUS_ACCEPTED && (isCurrentUserQuoteOwner() || isCurrentUserAdmin())) {
            enableUnlockQuote = true;
        }
        if (quote.SBQQ__Status__c != SBQQ_QuoteConstants.STATUS_DRAFT || quote.RecordType.DeveloperName == SBQQ_QuoteConstants.VIRTUAL_RECORD_TYPE) {
            enablePreviewDocument = true;
        }
        if (quote.SBQQ__Status__c == SBQQ_QuoteConstants.STATUS_PENDING_APPROVAL_OFFLINE_EDIT) {
            enableSubmitForOfflineEditApproval = true;
        }
    }

    public PageReference unlockQuote() {
        refreshPage = true;
        quote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_DRAFT;
        update quote;
        return null;
    }

    public PageReference generateDocument() {
        return redirect('/apex/PreGenerateDocumentPage?id=' + quote.Id);
    }

    public PageReference includeDocument() {
        return redirect('/apex/SBQQ__NewQuoteRelatedContent?id=' + quote.Id);
    }

    public PageReference previewDocument() {
        return redirect('/apex/SBQQ__PreviewDocument?id=' + quote.Id);
    }

    public PageReference submitForOfflineEditApproval() {
        update quote;
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(quote.Off_line_Edits__c);
        req.setObjectId(quote.Id);
        req.setSubmitterId(UserInfo.getUserId());
        req.setProcessDefinitionNameOrId(SBQQ_QuoteApprovalHandler.QUOTE_APPROVAL_PROCESS_OFFLINE_EDIT);
        req.setSkipEntryCriteria(true);
        Approval.ProcessResult result = Approval.process(req);
        refreshPage = true;
        return null;
    }

    private PageReference redirect(String pageUrl) {
        PageReference page = new PageReference(pageUrl);
        page.setRedirect(true);
        return page;
    }

    private Boolean isCurrentUserAdmin() {
        Profile profile = [SELECT PermissionsModifyAllData FROM Profile WHERE Id = :((String) UserInfo.getProfileId())][0];
        return profile.PermissionsModifyAllData;
    }

    private Boolean isCurrentUserQuoteOwner() {
        return UserInfo.getUserId() == quote.OwnerId;
    }

}