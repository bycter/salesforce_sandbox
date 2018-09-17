trigger ContractTrigger on Contract (before insert, after insert, before update, after update) {
    new ContractTriggerHandler().run();
}