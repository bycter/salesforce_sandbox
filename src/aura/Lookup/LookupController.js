({
    onfocus : function(component,event,helper) {
        component.set('v.hasError', false);
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        $A.util.removeClass(forOpen, 'slds-has-error');
        // Get Default 5 Records order by createdDate DESC
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },

    onblur : function(component,event,helper){
        component.set("v.listOfSearchRecords", null );
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        $A.util.removeClass(forclose, 'slds-has-error');
    },

    keyPressController : function(component, event, helper) {
        // get the search Input keyword
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and
        // call the helper
        // else close the lookup result List part.
        if( getInputkeyWord.length > 0 ){
            component.set('v.hasError', false);
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
            $A.util.removeClass(forOpen, 'slds-has-error');
        } else {
            // component.set('v.hasError', true)
            component.set("v.listOfSearchRecords", null );
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
            $A.util.removeClass(forclose, 'slds-has-error');
        }
    },

    // function for clear the Record Selaction
    clear :function(component,event,heplper){
        var pillTarget = component.find("lookup-pill");
        var lookUpTarget = component.find("lookupField");

        $A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');

        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');

        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );
        component.set("v.selectedRecord", {} );
    },

    initSelectedRecord: function(component, event, helper) {
        helper.handleRecordSelection(component);
    },

    // This function call when the end User Select any record from the result list.
    handleComponentEvent : function(component, event, helper) {
        // get the selected Account record from the COMPONETN event
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        component.set("v.selectedRecord" , selectedAccountGetFromEvent);

        helper.handleRecordSelection(component);
    },

    doValidate: function(component, e, helper) {
        var recordValue = component.get('v.selectedRecord');
        var required = component.get('v.required');
        var forOpen = component.find("searchRes");

        var hasError = required ? (!recordValue || !recordValue.Id) : false;
        component.set('v.hasError', hasError);
        if (hasError) {
            $A.util.addClass(forOpen, 'slds-has-error');
        } else {
            $A.util.removeClass(forOpen, 'slds-has-error');
        }
        return hasError;
    }
})