({
    sendForm: function(component, contactId, message) {
        var self = this;
        var spinner = component.find('spinner');
        $A.util.toggleClass(spinner, 'slds-hide');
        var action = component.get('c.sendDDForm');
        var accountId = component.get('v.selectedAccountId');
        action.setParams({
            recordId: component.get('v.recordId'),
            contactId: contactId,
            accountId: accountId,
            emailBody: message
        });
        action.setCallback(this, function(response) {
            if ( component.isValid() ) {
                var state = response.getState();
                console.log('state', state);
                if ( state === 'SUCCESS' ) {
                    $A.get("e.force:closeQuickAction").fire();
                    self.showSuccessToast();
                } else {
                    self.toastErrors(response);
                    var errors = response.getError();
                    console.error(errors);
                }
            }
            $A.util.toggleClass(spinner, 'slds-hide');
        });
        $A.enqueueAction(action);
    },

    showSuccessToast: function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "type": "success",
            "message": "The Direct Debit Form has been sent successfully."
        });
        toastEvent.fire();
    }
})