public class ProductRuleTriggerHandler extends TriggerHandler {

    protected override void beforeInsert() {
        List<ProductRule__c> productRules = Trigger.new;
        List<SBQQ__ProductRule__c> cpqProductRules = new List<SBQQ__ProductRule__c>();
        for (ProductRule__c productRule : productRules) {
            cpqProductRules.add((SBQQ__ProductRule__c) CpqObjectsTransformer.populateCPQObject(productRule, new SBQQ__ProductRule__c(Name='TestName')));
        }
        SBQQ.TriggerControl.disable();
        Database.upsert(cpqProductRules, SBQQ__ProductRule__c.Load_Id__c);
    }

    protected override void afterInsert(){
        delete [select Id from ProductRule__c];
    }
}