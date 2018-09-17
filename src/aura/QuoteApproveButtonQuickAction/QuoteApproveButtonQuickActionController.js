({
    doInit : function(cmp, event, helper) {
        helper.getApprovalInfo(cmp);
    },

    submitAction : function(cmp, event, helper) {
        helper.submitToApproval(cmp);
    },

    cancelAction : function(cmp, event, helper) {
        helper.dismissQuickAction();
    }
})