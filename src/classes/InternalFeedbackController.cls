public class InternalFeedbackController {

    public Flow.Interview.Internal_Feedback internalFeedback { get; set; }
    private static final String EMPTY = '';

    public InternalFeedbackController(ApexPages.StandardController stdController) {
    }

    private String getCaseId() {
        if (internalFeedback == null) {
            return EMPTY;
        }
        Object caseId = internalFeedback.getVariableValue('caseId');
        if (caseId == null || !(caseId instanceof String)) {
            return EMPTY;
        }
        return (String) caseId;
    }

    public PageReference getCaseLink() {
        String caseId = getCaseId();
        PageReference page = new PageReference('/' + caseId);
        if (String.isBlank(caseId)) {
            page = ApexPages.currentPage();
        }
        page.setRedirect(true);
        return page;
    }
}