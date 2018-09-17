({
    STATE_SUCCESS: "SUCCESS",
    STATE_ERROR: "ERROR",

    refreshView : function() {
        var refreshViewAction =  $A.get('e.force:refreshView');
        refreshViewAction.fire();
    },

    showToast : function(typeOrOptions, message, key, mode, duration, title) {
        if (typeof typeOrOptions === 'string') {
            this.showToast({
                type: typeOrOptions,
                message: message,
                key: key,
                mode: mode,
                duration: duration,
                title: title
            });
        } else {
            console.log('Fire toasts: ' + typeOrOptions.message);

            var options = {
                type: typeOrOptions.type ? typeOrOptions.type : 'other',
                key: typeOrOptions.key ? typeOrOptions.key : undefined,
                message: typeOrOptions.message,
                messageTemplate: typeOrOptions.messageTemplate ? typeOrOptions.messageTemplate : undefined,
                title: typeOrOptions.title ? typeOrOptions.title : undefined,
                mode: typeOrOptions.mode ? typeOrOptions.mode : undefined,
                duration: typeOrOptions.duration ? typeOrOptions.duration : undefined
            };

            var toast = $A.get('e.force:showToast');
            toast.setParams(options);
            toast.fire();
        }
    },

    toastErrors : function(response) {
        var errors = response.getError();
        if (errors) {
            if (errors[0] && !$A.util.isEmpty(errors[0].message)) {
                console.log('AuraHandledException handled');
                this.showToast({
                    type: "error",
                    message: errors[0].message,
                    mode: "dismissible",
                    duration: 5000,
                    title: "Error"
                });
            }
        } else {
            this.showToast({
                type: "error",
                message: "Unknown error",
                mode: "dismissible",
                duration: 5000,
                title: "Error"
            });
        }
    },

    logErrors : function (response) {
        var errors = response.getError();
        if (errors) {
            if (errors[0] && !$A.util.isEmpty(errors[0].message)) {
                console.log("Error message: " + errors[0].message);
            }
        } else {
            console.log("Unknown error");
        }
    },

    dismissQuickAction : function() {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})