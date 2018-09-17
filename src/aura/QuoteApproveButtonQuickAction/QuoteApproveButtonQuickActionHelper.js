({
    getApprovalInfo : function(cmp) {
        var action = cmp.get("c.getQuoteApprovalInfo");
        action.setParams({
            recordId : cmp.get("v.recordId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === this.STATE_SUCCESS) {
                var retValue = response.getReturnValue();
                cmp.set("v.approvalInfo", retValue);
                console.log(retValue);
            } else if(state === this.STATE_ERROR) {
                this.logErrors(response);
                this.toastErrors(response);
                this.dismissQuickAction();
            }
        });
        $A.enqueueAction(action);
    },

    submitToApproval : function(cmp, event) {
        cmp.set("v.isDisabledSubmitAction", true);
        var action = cmp.get("c.submitQuoteToApproval");
        action.setParams({
            recordId : cmp.get("v.recordId"),
            comments : cmp.get("v.comments")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === this.STATE_SUCCESS) {
                this.showToast("success", "Quote was submitted for approval.");
                this.refreshView();
            } else if(state === this.STATE_ERROR) {
                this.logErrors(response);
                this.toastErrors(response);
                cmp.set("v.isDisabledSubmitAction", false);
            }
            this.dismissQuickAction();
        });
        $A.enqueueAction(action);
    }
})