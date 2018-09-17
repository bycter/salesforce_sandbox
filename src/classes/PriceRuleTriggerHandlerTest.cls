@IsTest
public class PriceRuleTriggerHandlerTest {
    @IsTest
    static void testInsert() {
        Product2 product = RecordDmlTest.createProducts().get(0);

        PriceRule__c priceRule = new PriceRule__c();

        priceRule.Load_Id__c = 'testLoadId';
        priceRule.Name = 'Test Name';
        priceRule.CurrencyIsoCode = 'GBP';
        priceRule.Active__c = true;
        priceRule.AdvancedCondition__c = '(10 AND (20 OR 30))';
        priceRule.ConditionsMet__c = 'Custom';
        priceRule.ConfiguratorEvaluationEvent__c = 'Empty';
        priceRule.EvaluationEvent__c = 'On Calculate';
        priceRule.EvaluationOrder__c = 500;
        priceRule.LookupObject__c = 'Product2';
        priceRule.Product__c = product.Id;
        priceRule.TargetObject__c = 'Calculator';
        priceRule.CPQ_Config_Version__c = 10;

        List<PriceRule__c> priceRules = new List<PriceRule__c>{
                priceRule
        };

        insert priceRules;

        // price rule created
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__PriceRule__c]);

        //migration objects removed
        System.assertEquals(0, [SELECT COUNT() FROM PriceRule__c]);

        SBQQ__PriceRule__c cpqPriceRule = [
                SELECT Id, Name, Load_Id__c, CurrencyIsoCode, SBQQ__Active__c, SBQQ__AdvancedCondition__c,
                        SBQQ__ConditionsMet__c, SBQQ__ConfiguratorEvaluationEvent__c, SBQQ__EvaluationEvent__c,
                        SBQQ__LookupObject__c, SBQQ__Product__c, SBQQ__EvaluationOrder__c, SBQQ__TargetObject__c,
                        CPQ_Config_Version__c
                FROM SBQQ__PriceRule__c
        ];

        //all fields populated
        System.assertEquals(priceRule.Load_Id__c, cpqPriceRule.Load_Id__c);
        System.assertEquals(priceRule.Name, cpqPriceRule.Name);
        System.assertEquals(priceRule.CurrencyIsoCode, cpqPriceRule.CurrencyIsoCode);
        System.assertEquals(priceRule.Active__c, cpqPriceRule.SBQQ__Active__c);
        System.assertEquals(priceRule.AdvancedCondition__c, cpqPriceRule.SBQQ__AdvancedCondition__c);
        System.assertEquals(priceRule.ConditionsMet__c, cpqPriceRule.SBQQ__ConditionsMet__c);
        System.assertEquals(priceRule.ConfiguratorEvaluationEvent__c, cpqPriceRule.SBQQ__ConfiguratorEvaluationEvent__c);
        System.assertEquals(priceRule.EvaluationEvent__c, cpqPriceRule.SBQQ__EvaluationEvent__c);
        System.assertEquals(priceRule.LookupObject__c, cpqPriceRule.SBQQ__LookupObject__c);
        System.assertEquals(priceRule.Product__c, cpqPriceRule.SBQQ__Product__c);
        System.assertEquals(priceRule.EvaluationOrder__c, cpqPriceRule.SBQQ__EvaluationOrder__c);
        System.assertEquals(priceRule.TargetObject__c, cpqPriceRule.SBQQ__TargetObject__c);
        System.assertEquals(priceRule.CPQ_Config_Version__c, cpqPriceRule.CPQ_Config_Version__c);
    }
}