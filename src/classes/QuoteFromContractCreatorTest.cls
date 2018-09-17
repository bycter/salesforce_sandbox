@isTest
public class QuoteFromContractCreatorTest {
    @isTest
    public static void generateQuoteFromContract(){
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
        Contract contract = RecordDmlTest.createContract(quote, RecordDmlTest.createProperty());
        SBQQ__QuoteLine__c line = [SELECT SBQQ__Product__c, Inventory__c, Id FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];
        SBQQ__Subscription__c subscription = RecordDmlTest.createSubscription(line, contract);
        Opportunity opp = RecordDmlTest.createOpportunity(OpportunityService.SERVICED_RECORD_TYPE);
        opp = GenerateQuoteController.findOpportunityById(opp.Id);
        List<String> contractsList = new List<String>();
        contractsList.add(contract.Id);
        Test.startTest();
        quote = QuoteFromContractCreator.generate(opp, contract.Id, contractsList, SBQQ_QuoteConstants.CONVENTIONAL_RECORD_TYPE);
        Test.stopTest();
        System.assertEquals(OpportunityService.SERVICED_RECORD_TYPE, [SELECT RecordType.DeveloperName FROM SBQQ__Quote__c WHERE Id = :quote.Id].RecordType.DeveloperName);
        System.assert([SELECT id FROM ContractToQuote__c WHERE Quote__c = :quote.Id AND Contract__c = :contract.Id].size() != 0);
        System.assertEquals(contract.Contract_Term__c, [SELECT Term__c FROM SBQQ__QuoteLine__C WHERE Headline_Item_Subscription_Term__c != null LIMIT 1].Term__c);
    }
}