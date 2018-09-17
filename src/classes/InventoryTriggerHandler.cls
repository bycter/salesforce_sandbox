public with sharing class InventoryTriggerHandler extends TriggerHandler {

    private static final String ERROR_MSG_FIELD = 'You do not have permission to edit this field';
    private static final String ERROR_MSG_RECORD_TYPE = 'You do not have permission to change Record Type';

    public override void beforeInsert() {
        RecordTypeHelper.setRTByDeveloperNameField(Trigger.new, 'RecordTypeDeveloperName__c');
    }

    public override void beforeUpdate() {
        validateFieldAccess((List<Inventory__c>) Trigger.new, (Map<Id, Inventory__c>) Trigger.oldMap);
    }

    private void validateFieldAccess(List<Inventory__c> newInventories, Map<Id, Inventory__c> oldInventories) {
        if (!(Schema.SObjectType.Inventory__c.isCreateable()
                && Schema.SObjectType.Inventory__c.isAccessible()
                && Schema.SObjectType.Inventory__c.isUpdateable())) {
            for (Inventory__c inventory : newInventories) {
                Inventory__c oldInventory = oldInventories.get(inventory.Id);
                if (inventory.Name != oldInventory.Name) {
                    inventory.Name.addError(ERROR_MSG_FIELD);
                }
                if (inventory.RecordTypeId != oldInventory.RecordTypeId) {
                    inventory.RecordTypeId.addError(ERROR_MSG_RECORD_TYPE);
                }
            }
        }
    }
}