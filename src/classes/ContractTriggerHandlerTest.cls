@IsTest
public with sharing class ContractTriggerHandlerTest {

    @IsTest
    public static void givenContractWhenInsertOrUpdateThenRTIsSet() {
        Contract contract = RecordDmlTest.createContract();

        contract = [SELECT Id, RecordTypeId, Status FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(contract.RecordTypeId, RecordTypeHelper.getRtIdByDeveloperName(ContractTriggerHandler.CONTRACT_API_NAME, ContractTriggerHandler.NOT_ACTIVATED_RT_DEV_NAME));

        contract.Status = 'Live';
        update contract;

        contract = [SELECT Id, RecordTypeId, Status FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(contract.RecordTypeId, RecordTypeHelper.getRtIdByDeveloperName(ContractTriggerHandler.CONTRACT_API_NAME, ContractTriggerHandler.ACTIVATED_RT_DEV_NAME));

        contract.Status = 'Draft';
        update contract;

        contract = [SELECT Id, RecordTypeId, Status FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(contract.RecordTypeId, RecordTypeHelper.getRtIdByDeveloperName(ContractTriggerHandler.CONTRACT_API_NAME, ContractTriggerHandler.NOT_ACTIVATED_RT_DEV_NAME));

        contract.Status = 'Activated';
        update contract;

        contract = [SELECT Id, RecordTypeId, Status FROM Contract WHERE Id = :contract.Id];
        System.assertEquals(contract.RecordTypeId, RecordTypeHelper.getRtIdByDeveloperName(ContractTriggerHandler.CONTRACT_API_NAME, ContractTriggerHandler.ACTIVATED_RT_DEV_NAME));

    }

    @IsTest
    public static void givenContractWhenActivatedThenRelatedOpportunityContractActiveFieldIsSet() {
        SBQQ.TriggerControl.disable();

        Property__c property = RecordDmlTest.createProperty();
        Opportunity opportunity = RecordDmlTest.createOpportunity('Conventional');
        SBQQ__Quote__c quote = RecordDmlTest.createQuote(property, opportunity, 'Conventional');

        Contract contract = RecordDmlTest.createContract();
        contract.SBQQ__Quote__c=quote.Id;

        contract.Status = 'Activated';
        update contract;

        System.assert([SELECT Contract_Activated__c FROM Opportunity WHERE Id = :opportunity.Id].Contract_Activated__c);
    }
}