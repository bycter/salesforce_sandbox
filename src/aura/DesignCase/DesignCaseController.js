({
    doInit : function(cmp, event, helper) {
        var isEditCase = cmp.get("v.recordId") != null && cmp.get("v.recordId") !== '';
        if (isEditCase) {
            sforce.one.editRecord(cmp.get("v.recordId"));
        } else {
            helper.createNewCaseRecord(cmp);
        }
    },
    save : function(cmp, event, helper) {
        cmp.find("edit").get("e.recordSave").fire();
    }
})