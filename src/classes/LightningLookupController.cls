/**
 * @description Controller class for LightningLookup component
 */
public with sharing class LightningLookupController {

    @AuraEnabled
    public static List <sObject> fetchLookUpValues(String searchKeyWord, String objectName, String accountId, String soqlFilter) {
        String searchKey = searchKeyWord + '%';
        System.debug('searchKeyWord: ' + searchKeyWord);
        System.debug('objectName: ' + objectName);

        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
        String sQuery =  'SELECT id, Name FROM ' + objectName;
        Boolean hasAccount = String.isNotBlank(accountId);
        Boolean hasFilter = String.isNotBlank(soqlFilter);
        Boolean hasSearchString = String.isNotBlank(searchKey);

        if (hasAccount || hasFilter || hasSearchString) {
            sQuery +=' WHERE';
        }
        if (hasAccount) {
            sQuery += ' AccountId = :accountId';
            if (hasFilter || hasSearchString) {
                sQuery += ' AND ';
            }
        }
        if (hasFilter) {
            sQuery += ' ( ' + soqlFilter + ' ) ';
            if (hasSearchString) {
                sQuery += ' AND ';
            }
        }
        if (hasSearchString) {
            sQuery += ' Name LIKE: searchKey ';
        }

        sQuery += ' ORDER BY CreatedDate DESC LIMIT 5';
        List <sObject> results = Database.query(sQuery);
        return results;
    }
}