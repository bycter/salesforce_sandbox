({
    handleSend: function(component, event, helper) {
        var contactId = component.find('lookup').get('v.selectedRecord.Id');
        var message = component.find('emailBody').get('v.value');
        if ( !contactId ) {
            component.find('lookup').set('v.hasError', true);
            $A.util.addClass(component.find('lookup').find('searchRes'), 'slds-has-error');
        } else {
            helper.sendForm(component, contactId, message)
        }
    },

    handleAccountChange: function(component, event, helper) {
        var selectedRecord = event.getParam('recordByEvent');
        if ( selectedRecord && selectedRecord.Id.startsWith('001') ) {
            component.set('v.selectedAccountId', selectedRecord.Id);
            var contactLookup = component.find('lookup');
            contactLookup.set('v.accountId', selectedRecord.Id);
        }
    },

    handleRecordUpdated: function(component, event, helper) {
        var recordFields = component.get('v.recordFields');
        if ( recordFields.Account__c ) {
            var accLookup = component.find('accLookup');
            accLookup.set('v.selectedRecord', {Id: recordFields.Account__c, Name: recordFields.Account__r.Name});
            accLookup.initSelectedRecord();
            component.set('v.selectedAccountId', recordFields.Account__c);
        }
    },

    handleCancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})