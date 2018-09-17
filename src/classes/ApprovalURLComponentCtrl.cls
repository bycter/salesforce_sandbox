public class ApprovalURLComponentCtrl {

    public String recordId { get; set; }

    public String getApprovalURL() {
        return getApprovalURL(recordId);
    }

    private static String getApprovalURL(String recordId) {
        String url = '';
        List<ProcessInstanceWorkitem> processInstanceWorkitems = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :recordId
        ];
        if (processInstanceWorkitems.size() > 0) {
            url = 'https://' + System.URL.getSalesforceBaseUrl().getHost() +
                    '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + processInstanceWorkitems.get(0).Id;
        }
        return url;
    }

}