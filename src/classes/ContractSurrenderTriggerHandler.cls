public class ContractSurrenderTriggerHandler extends TriggerHandler {

    public override void beforeInsert() {
        validateOnlyOneSurrenderForOneContract(Trigger.new);
    }

    public override void afterUpdate() {
        handleCompletedSurrender(Trigger.new);
    }

    public override void afterInsert() {
        handleCompletedSurrender(Trigger.new);
    }

    private void handleCompletedSurrender(List<Contract_Surrender__c> surrenders) {
        Map<Id, Contract> idContractMap = new Map<Id, Contract>();
        for (Contract_Surrender__c surrender : surrenders) {

            Contract_Surrender__c oldSurrender = Trigger.oldMap != null
                ? (Contract_Surrender__c) Trigger.oldMap.get(surrender.Id) 
                : null;

            Date surrenderdate = surrender.Proposed_date_of_surrender__c;
            Date oldSurrenderDate = oldSurrender != null 
                ? oldSurrender.Proposed_date_of_surrender__c
                : null;
            Id contractId = surrender.Contract__c;

            if ((surrenderdate != null && surrenderdate != oldSurrenderDate) ) {

                idContractMap.put(contractId, new Contract(
                    Id = contractId,
                    Surrender_Date__c = surrender.Proposed_date_of_surrender__c
                ));
            }

            if (surrender.Status__c == 'Complete' &&  (oldSurrender == null || oldSurrender.Status__c != 'Complete')) {
                Contract theContact = idContractMap.get(contractId);

                idContractMap.put(contractId, theContact != null ? theContact: new Contract(
                    Id = contractId,
                    Surrender_Date__c = surrender.Proposed_date_of_surrender__c
                ));
            }
        }

        if (!idContractMap.isEmpty()) {
            update idContractMap.values();
        }
    }

    private void validateOnlyOneSurrenderForOneContract(List<Contract_Surrender__c> surrenders) {
        Set<Id> contractsIds = SObjectUtils.getIdSetFromObjects(surrenders, 'Contract__c');
        Map<Id, Contract> contractsMap = new Map<Id, Contract>([SELECT Id FROM Contract WHERE Id IN (SELECT Contract__c FROM Contract_Surrender__c WHERE Contract__c IN :contractsIds)]);

        for (Contract_Surrender__c surrender : surrenders) {
            if (contractsMap.containsKey(surrender.Contract__c)) {
                surrender.addError('This contract already have a Surrender!');
            }
        }
    }
}