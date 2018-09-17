trigger SBQQ_QuoteTrigger on SBQQ__Quote__c (before insert, before update, after update) {
    new SBQQ_QuoteTriggerHandler().run();
}