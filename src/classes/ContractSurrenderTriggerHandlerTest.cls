@IsTest
public class ContractSurrenderTriggerHandlerTest {
    @TestSetup
    public static void init() {
        //Account account = RecordDmlTest.createAccount();
        Property__c property = RecordDmlTest.createProperty();
        Opportunity opportunity = RecordDmlTest.createOpportunity(OpportunityService.CONVENTIONAL_RECORD_TYPE);
        SBQQ__Quote__c quote = RecordDmlTest.createQuote(property,opportunity,OpportunityService.CONVENTIONAL_RECORD_TYPE);

        Contract contract = RecordDmlTest.createContract(quote, property);

        Contract_Surrender__c surrender = generateSurrender(contract);
        insert surrender;
    }

    @IsTest
    public static void givenSurrenderContractWhenCompletedThenContractFieldPopulated() {
        Contract contract = [SELECT Id, Surrender_Date__c FROM Contract];
        Contract_Surrender__c surrender = [SELECT Id, Proposed_date_of_surrender__c, Status__c FROM Contract_Surrender__c];

        System.assertEquals(1, [SELECT COUNT() FROM Contract WHERE Id = :contract.Id AND Surrender_Date__c = :surrender.Proposed_date_of_surrender__c]);

        contract.Surrender_Date__c = null;
        update contract;

        surrender.Status__c = 'New';
        update surrender;

        System.assertEquals(0, [SELECT COUNT() FROM Contract WHERE Id = :contract.Id AND Surrender_Date__c = :surrender.Proposed_date_of_surrender__c]);

        surrender.Status__c = 'Complete';
        update surrender;

        System.assertEquals(1, [SELECT COUNT() FROM Contract WHERE Id = :contract.Id AND Surrender_Date__c = :surrender.Proposed_date_of_surrender__c]);

    }

    @IsTest
    public static void givenSurrenderWhenSecondSurrenderCreatedThenErrorAdded() {
        Contract contract = [SELECT Id, Name, Surrender_Date__c FROM Contract];
        try {
            insert generateSurrender(contract);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('already have a Surrender'));
        }
    }

    private static Contract_Surrender__c generateSurrender(Contract contract) {
        return new Contract_Surrender__c(
                Date_Surrender_Triggered__c = Date.today(),
                Proposed_date_of_surrender__c = Date.today(),
                Contract__c = contract.Id,
                Name = ('Surrender: ' + contract.Name),
                Deposit__c = 100,
                Status__c = 'Complete',
                Break_Penalty_Premium_Billing_Status__c = 'To be billed',
                Budget_Dilapidations_Billing_Status__c = 'To be billed',
                Deposit_Interest_Billing_Status__c = 'To be billed',
                Deposit_Billing_Status__c = 'To be billed',
                Final_Dilapidations_Billing_Status__c = 'To be billed',
                Interim_Dilapidations_Billing_Status__c = 'To be billed',
                Suite_Restoration_Billing_Status__c = 'To be billed',
                Terminal_Dilapidations_Billing_Status__c = 'To be billed',
                Surrender_Premium_Billing_Status__c = 'To be billed',
                Is_the_customer_liable_for_Service_Chrg__c = 'Yes',
                Is_the_customer_liable_for_electricity__c = 'Yes'
        );
    }
}