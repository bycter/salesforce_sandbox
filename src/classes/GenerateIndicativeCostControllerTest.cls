@isTest
public class GenerateIndicativeCostControllerTest {
    @isTest
    public static void testController() {
        ApexPages.StandardController standardController = new ApexPages.StandardController(new Indicative_Cost__c());
        GenerateIndicativeCostController indicativeCostController = new GenerateIndicativeCostController(standardController);
        System.assertNotEquals(null, indicativeCostController.cost);
    }
}