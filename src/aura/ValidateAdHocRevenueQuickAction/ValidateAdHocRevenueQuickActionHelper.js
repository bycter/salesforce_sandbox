({
    validateAdHocRevenue : function(cmp) {
        var action = cmp.get("c.validateFields");
        action.setParams({
            recordId : cmp.get("v.recordId"),
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === this.STATE_SUCCESS) {
                this.showToast("success", "Ad-hoc Revenue is valid.");
            } else if(state === this.STATE_ERROR) {
                this.logErrors(response);
                this.toastErrors(response);
            }
            this.dismissQuickAction();
        })
        $A.enqueueAction(action);
    },
})