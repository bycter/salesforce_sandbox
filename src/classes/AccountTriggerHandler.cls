public class AccountTriggerHandler extends TriggerHandler {
    public static final String SLA_PROCESS_NAME = 'Standard Lease Transaction Process';
    
    protected override void afterInsert() {
        addSLAEntitlement();
    }

    protected  override void beforeDelete() {
        removeSLAEntitlements();
    }

    private void addSLAEntitlement() {
        List<SlaProcess> processes = [select Id from SlaProcess where Name = :SLA_PROCESS_NAME];
        Id slaProcessId = null;
        if (processes.size() == 1) {
            slaProcessId = [select Id from SlaProcess where Name = :SLA_PROCESS_NAME][0].Id;
        } else {
            //there is no SLA process no sense to continue
            return;
        }

        List<Entitlement> entitlements = new List<Entitlement>();
        for (Account account : (List<Account>) Trigger.new) {
            entitlements.add(new Entitlement(AccountId = account.id, SlaProcessId = slaProcessId, Name='SLA Entitlement'));
        }
        
        insert entitlements;
    }

    private void removeSLAEntitlements() {
        List<Account> accountsToDelete = (List<Account>) Trigger.old;
        System.debug('accountsToDelete' + accountsToDelete);
        List<Entitlement> entitlements = [
                SELECT id
                FROM Entitlement
                WHERE AccountId in : accountsToDelete
        ];
        System.debug('entitlements'+ entitlements);
        delete entitlements;
    }

}