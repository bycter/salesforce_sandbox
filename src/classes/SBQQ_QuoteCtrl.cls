public with sharing class SBQQ_QuoteCtrl {

    @AuraEnabled
    public static void submitQuoteToApproval(Id recordId, String comments) {
        List<SBQQ__QuoteLine__c> headLines = SBQQ_QuoteService.getHeadLinesItems(recordId);
        Map<Id, List<SBQQ__QuoteLine__c>> headLinesByQuoteId = SObjectUtils.getIdMapFromObjects(headLines, 'SBQQ__Quote__c');
        List<SBQQ_QuoteApprovalHandler.ApprovalInfo> approvalInfos = SBQQ_QuoteApprovalHandler.getApprovalInfos(headLinesByQuoteId);
        SBQQ_QuoteApprovalHandler.ApprovalInfo approvalInfo = approvalInfos.isEmpty() ? null : approvalInfos.get(0);
        System.debug('SBQQ_QuoteCtrl.submitQuoteToApproval: approvalInfo: ' + approvalInfo + ' comments: ' + comments);
        Boolean autoApprove = false;
        Id submitterId = UserInfo.getUserId();
        if (submitterId == approvalInfo.approver.Id) {
            autoApprove = true;
        }
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(comments);
        req.setObjectId(recordId);
        req.setSubmitterId(submitterId);
        req.setProcessDefinitionNameOrId(SBQQ_QuoteApprovalHandler.QUOTE_APPROVAL_PROCESS);
        req.setSkipEntryCriteria(true);
        req.setNextApproverIds(new List<Id>{
                approvalInfo.approver.Id
        });
        Approval.ProcessResult result = Approval.process(req);
        List<Id> newWorkItemIds = result.getNewWorkitemIds();
        if (autoApprove && newWorkItemIds.size() > 0) {
            Approval.ProcessWorkitemRequest approveReq = new Approval.ProcessWorkitemRequest();
            approveReq.setComments('Auto Approving request.');
            approveReq.setAction(SBQQ_QuoteApprovalHandler.APPROVAL_ACTION_APPROVE);
            approveReq.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult approveResult = Approval.process(approveReq);
        }
    }

    @AuraEnabled
    public static SBQQ_QuoteApprovalHandler.ApprovalInfo getQuoteApprovalInfo(Id recordId) {
        List<SBQQ__QuoteLine__c> headLines = SBQQ_QuoteService.getHeadLinesItems(recordId);
        Map<Id, List<SBQQ__QuoteLine__c>> headLinesByQuoteId = SObjectUtils.getIdMapFromObjects(headLines, 'SBQQ__Quote__c');
        List<SBQQ_QuoteApprovalHandler.ApprovalInfo> approvalInfos = SBQQ_QuoteApprovalHandler.getApprovalInfos(headLinesByQuoteId);
        SBQQ_QuoteApprovalHandler.ApprovalInfo approvalInfo = null;
        if (!approvalInfos.isEmpty()) {
            approvalInfo = approvalInfos.get(0);
        } else {
            throw new AuraHandledException('You can not send for approval without adding products');
        }
        System.debug('SBQQ_QuoteCtrl.getApprovalInfo: approvalInfo: ' + approvalInfo);
        return approvalInfo;
    }

}