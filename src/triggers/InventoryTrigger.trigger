trigger InventoryTrigger on Inventory__c (before insert, before update) {
    new InventoryTriggerHandler().run();
}