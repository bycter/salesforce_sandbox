({
	convertPotentialContact: function(component) {
		var self = this;
		var action = component.get('c.upsertPotentialContact');
		action.setParam('potentialContactId', component.get('v.recordId'));
		action.setCallback(this, function(response) {
			if ( component.isValid() ) {
				var state = response.getState();
				if ( state === 'SUCCESS' ) {
					var createdContactId = response.getReturnValue();
					console.log('createdContactId', createdContactId);
					self.showToast();
					self.navigateToContact(createdContactId);
				} else {
					var errors = response.getError();
					if ( errors ) {
						component.set('v.errorMessage', errors[0].message);
					}
					console.error(errors);
				}
			}
		});
		$A.enqueueAction(action);
	},

	navigateToContact: function(contactId) {
		var navigateEvt = $A.get('e.force:navigateToSObject');
		console.log('contactId:', contactId);
		navigateEvt.setParams({
			'recordId': contactId
		});
		navigateEvt.fire();
	},

	showToast: function() {
		var toastEvent = $A.get("e.force:showToast");
		toastEvent.setParams({
			"title": "Success!",
			"type": "success",
			"message": "The Potential Contact has been converted successfully."
		});
		toastEvent.fire();
	}
})