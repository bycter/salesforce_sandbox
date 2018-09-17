({
    searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method
        var action = component.get("c.fetchLookUpValues");
        // set param to method
        action.setParams({
            'searchKeyWord': getInputkeyWord || '',
            'objectName': component.get("v.objectAPIName"),
            'accountId': component.get('v.accountId') || '',
            'soqlFilter' : component.get("v.soqlFilter") || ''
        });
        // set a callBack
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
        });
        // enqueue the Action
        $A.enqueueAction(action);
    },

    handleRecordSelection : function(component) {
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');

        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');

        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');

        $A.util.removeClass(forclose, 'slds-has-error');
        component.set('v.hasError', false);
    },
})