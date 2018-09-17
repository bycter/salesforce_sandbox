({
	init: function(component, event, helper) {
		var recordId = component.get('v.recordId');
		helper.convertPotentialContact(component);
	}
})