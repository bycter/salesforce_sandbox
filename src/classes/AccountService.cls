/**
 * @description Class contains general functionality related to Account object
 */
public with sharing class AccountService {

    /**
     * @description Updated Company_Registration_Number__c for specified Accounts
     */
    public void updateCompanyRegistrationNumbers(Map<Id, String> accountIdToCompanyNumberMap) {
        if ( accountIdToCompanyNumberMap != null ) {
            Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :accountIdToCompanyNumberMap.keySet()]);
            for ( Account theAccount : accountsMap.values() ) {
                theAccount.Company_Registration_Number__c = accountIdToCompanyNumberMap.get(theAccount.Id);
            }
            update accountsMap.values();
        }
    }
}