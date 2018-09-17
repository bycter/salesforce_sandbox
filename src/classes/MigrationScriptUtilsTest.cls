@isTest
public with sharing class MigrationScriptUtilsTest {
    @isTest
    public static void populateStatusAndVersionTest(){
        SBQQ__LookupData__c sbqqObject = new SBQQ__LookupData__c(Is_Old_Version__c = false);
        smagicinteract__incoming_lookup_config__c nonSbqqObject = new smagicinteract__incoming_lookup_config__c(Is_Old_Version__c = false, smagicinteract__objectName__c = 'test');
        Config_Version__c version = new Config_Version__c(CPQ_Version__c = 2, SetupOwnerId = UserInfo.getOrganizationId());
        insert version;
        insert sbqqObject;
        insert nonSbqqObject;
        MigrationScriptUtils.populateOldStatus(true);
        System.assertEquals(true, [SELECT Is_Old_Version__c FROM SBQQ__LookupData__c WHERE Id = :sbqqObject.Id][0].Is_Old_Version__c);
        System.assertEquals(true, [SELECT Is_Old_Version__c FROM smagicinteract__incoming_lookup_config__c WHERE Id = :nonSbqqObject.Id][0].Is_Old_Version__c);

        MigrationScriptUtils.setCurrentVersion();
        System.assertEquals(version.CPQ_Version__c, [SELECT CPQ_Config_Version__c FROM SBQQ__LookupData__c WHERE Id = :sbqqObject.Id][0].CPQ_Config_Version__c);

        MigrationScriptUtils.incrementVersion();
        System.assertEquals(version.CPQ_Version__c + 1, [SELECT Id, CPQ_Version__c FROM Config_Version__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()].CPQ_Version__c);

        MigrationScriptUtils.removeOldRecords();
        System.assertEquals(0, [SELECT Id FROM SBQQ__LookupData__c WHERE Id = :sbqqObject.Id].size());
    }
}