trigger PriceRuleTrigger on PriceRule__c (before insert, after insert ) {
    new PriceRuleTriggerHandler().run();
}