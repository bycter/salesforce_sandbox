@IsTest
public class ProductRuleTriggerHandlerTest {
    @IsTest
    static void testInsert() {
        ProductRule__c productRule = new ProductRule__c();

        productRule.Load_Id__c = 'testLoadId';
        productRule.Name = 'Test Name';
        productRule.CurrencyIsoCode = 'GBP';
        productRule.Active__c = true;
        productRule.AdvancedCondition__c = '100 AND (201 OR 202)';
        productRule.ConditionsMet__c = 'Custom';
        productRule.ErrorMessage__c = 'ERROR!';
        productRule.EvaluationEvent__c = 'Save';
        productRule.EvaluationOrder__c = 500;
        productRule.LookupProductField__c = 'smth1';
        productRule.LookupMessageField__c = 'smth2';
        productRule.LookupObject__c = 'smth3';
        productRule.LookupRequiredField__c = 'smth4';
        productRule.LookupTypeField__c = 'smth5';
        productRule.Scope__c = 'Product';
        productRule.Type__c = 'Validation';
        productRule.CPQ_Config_Version__c = 10;

        List<ProductRule__c> productRules = new List<ProductRule__c>{
                productRule
        };

        insert productRules;

        // product rule created
        System.assertEquals(1, [SELECT COUNT() FROM SBQQ__ProductRule__c]);

        //migration objects removed
        System.assertEquals(0, [SELECT COUNT() FROM ProductRule__c]);

        SBQQ__ProductRule__c cpqProductRule = [
                select Id, Name, Load_Id__c, CurrencyIsoCode, SBQQ__Active__c, SBQQ__AdvancedCondition__c,
                        SBQQ__ConditionsMet__c, SBQQ__ErrorMessage__c, SBQQ__EvaluationEvent__c, SBQQ__EvaluationOrder__c,
                        SBQQ__LookupProductField__c, SBQQ__LookupMessageField__c, SBQQ__LookupObject__c,
                        SBQQ__LookupRequiredField__c, SBQQ__LookupTypeField__c,
                        SBQQ__Scope__c, SBQQ__Type__c, CPQ_Config_Version__c
                FROM SBQQ__ProductRule__c
        ];

        System.assertEquals(productRule.Name, cpqProductRule.Name);
        System.assertEquals(productRule.Load_Id__c, cpqProductRule.Load_Id__c);
        System.assertEquals(productRule.CurrencyIsoCode, cpqProductRule.CurrencyIsoCode);
        System.assertEquals(productRule.CPQ_Config_Version__c, cpqProductRule.CPQ_Config_Version__c);
        System.assertEquals(productRule.Active__c, cpqProductRule.SBQQ__Active__c);
        System.assertEquals(productRule.AdvancedCondition__c, cpqProductRule.SBQQ__AdvancedCondition__c);
        System.assertEquals(productRule.ConditionsMet__c, cpqProductRule.SBQQ__ConditionsMet__c);
        System.assertEquals(productRule.ErrorMessage__c, cpqProductRule.SBQQ__ErrorMessage__c);
        System.assertEquals(productRule.EvaluationEvent__c, cpqProductRule.SBQQ__EvaluationEvent__c);
        System.assertEquals(productRule.EvaluationOrder__c, cpqProductRule.SBQQ__EvaluationOrder__c);
        System.assertEquals(productRule.LookupProductField__c, cpqProductRule.SBQQ__LookupProductField__c);
        System.assertEquals(productRule.LookupMessageField__c, cpqProductRule.SBQQ__LookupMessageField__c);
        System.assertEquals(productRule.LookupObject__c, cpqProductRule.SBQQ__LookupObject__c);
        System.assertEquals(productRule.LookupRequiredField__c, cpqProductRule.SBQQ__LookupRequiredField__c);
        System.assertEquals(productRule.LookupTypeField__c, cpqProductRule.SBQQ__LookupTypeField__c);
        System.assertEquals(productRule.Scope__c, cpqProductRule.SBQQ__Scope__c);
        System.assertEquals(productRule.Type__c, cpqProductRule.SBQQ__Type__c);
    }
}