trigger ProductRuleTrigger on ProductRule__c (before insert, after insert) {
    new ProductRuleTriggerHandler().run();
}