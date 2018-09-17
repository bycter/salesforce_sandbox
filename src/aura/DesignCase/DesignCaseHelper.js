({
    createNewCaseRecord : function(cmp) {
        var action = cmp.get("c.getCaseParams");
        action.setParams({
            "quoteId" : cmp.get("v.quoteId")
        });
        action.setCallback(this, function (response) {
            var state = response.getState();
            if(state === this.STATE_SUCCESS) {
                var retValue = response.getReturnValue();
                var defaultFieldValues = {
                    "FitOutLink__c" : retValue.quoteLineId || undefined,
                    "AccountId" : retValue.accountId || undefined,
                    "Opportunity__c" : retValue.opportunityId || undefined,
                    "Inventory__c" : retValue.inventoryId || undefined,
                    "OwnerId" : retValue.ownerId || undefined,
                    "Quote__c" : cmp.get("v.quoteId") || undefined,
                };
                sforce.one.createRecord("Case", retValue.recordTypeId, defaultFieldValues);
            } else if(state === this.STATE_ERROR) {
                this.logErrors(response);
                this.toastErrors(response);
            }
        });
        $A.enqueueAction(action);
    }
})