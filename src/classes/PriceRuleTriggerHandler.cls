public class PriceRuleTriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        List<PriceRule__c> priceRules = Trigger.new;
        List<SBQQ__PriceRule__c> cpqPriceRules = new List<SBQQ__PriceRule__c>();
        for (PriceRule__c priceRule : priceRules) {
            cpqPriceRules.add((SBQQ__PriceRule__c) CpqObjectsTransformer.populateCPQObject(priceRule, new SBQQ__PriceRule__c()));
        }
        SBQQ.TriggerControl.disable();
        Database.upsert(cpqPriceRules, SBQQ__PriceRule__c.Load_Id__c);
    }

    protected override void afterInsert() {
        delete [select Id from PriceRule__c];
    }
}