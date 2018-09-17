trigger ContractSurrenderTrigger on Contract_Surrender__c (before insert, after insert, after update) {
    new ContractSurrenderTriggerHandler().run();
}