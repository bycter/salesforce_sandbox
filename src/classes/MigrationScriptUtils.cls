/**
 * Class for populating Load_Id__c in needed objects before export
 */
public class MigrationScriptUtils {
    private static final Set<String> CPQ_SOBJECT_API_NAMES = new Set<String>{
            //'Pricebook2',
            //'Product2',
            //'PricebookEntry',
            'SBQQ__LookupData__c',
            'SBQQ__PriceRule__c',
            'SBQQ__SummaryVariable__c',
            'SBQQ__PriceCondition__c',
            'SBQQ__AttributeSet__c',
            'SBQQ__ProductFeature__c',
            'SBQQ__ProductOption__c',
            'SBQQ__OptionConstraint__c',
            'SBQQ__ProductAttributeSet__c',
            'SBQQ__ProductRule__c',
            'SBQQ__ConfigurationRule__c',
            'SBQQ__ConfigurationAttribute__c',
            'SBQQ__ProductAttribute__c',
            'SBQQ__LookupQuery__c',
            'SBQQ__PriceAction__c',
            'SBQQ__AttributeValue__c',
            'SBQQ__ErrorCondition__c',
            'SBQQ__ProductAction__c',
            'SBQQ__CustomAction__c',
            'SBQQ__CustomActionCondition__c',
            'SBQQ__SearchFilter__c',
            'SBQQ__CustomScript__c'
    };

    private static final Set<String> NON_CPQ_SOBJECT_API_NAMES = new Set<String>{
            //'c2g__codaGeneralLedgerAccount__c',
            //'c2g__codaCompany__c',
            //'c2g__codaTaxCode__c',
            //'Inventory__c',
            //'Property__c',
            //'Design_Costs_Settings__c',
            'smagicinteract__incoming_lookup_config__c',
            'smagicinteract__SMS_SenderId__c',
            'smagicinteract__SenderId_Profile_Map__c',
            'smagicinteract__SMS_Template_Type__c',
            'smagicinteract__SMS_Template__c',
            'smagicreminder__EventReminderConfig__c'
    };

    private static final String CPQ_QUERY_STRING_BEGIN = 'select Id, Load_Id__c, CPQ_Config_Version__c from ';

    private static final String NON_CPQ_QUERY_STRING_BEGIN = 'select Id, Load_Id__c, Config_Version__c from ';

    public static void populateOldStatus(Boolean isOld){
        for (String sObjectApiName : CPQ_SOBJECT_API_NAMES) {
            setOldStatus(CPQ_QUERY_STRING_BEGIN + sObjectApiName, isOld);
        }
        for (String sObjectApiName : NON_CPQ_SOBJECT_API_NAMES) {
            setOldStatus(NON_CPQ_QUERY_STRING_BEGIN + sObjectApiName, isOld);
        }
    }

    private static void setOldStatus(String queryString, Boolean status){
        SBQQ.TriggerControl.disable();
        List<sObject> sobjectList = Database.query(queryString);
        for (sObject obj : sobjectList) {
            obj.put('Is_Old_Version__c', status);
            if (obj.get('Load_Id__c') == null || obj.get('Load_Id__c') == '') {
                obj.put('Load_Id__c', obj.get('Id'));
            }
        }
        update sobjectList;
    }

    public static void removeOldRecords(){
        SBQQ.TriggerControl.disable();
        CPQ_SOBJECT_API_NAMES.remove('SBQQ__CustomAction__c');
        CPQ_SOBJECT_API_NAMES.remove('SBQQ__CustomActionCondition__c');
        for (String sObjectApiName : CPQ_SOBJECT_API_NAMES) {
            List<sObject> sobjectList = Database.query(CPQ_QUERY_STRING_BEGIN + sObjectApiName + ' where Is_Old_Version__c = true');
            try {
                delete sobjectList;
            } catch (Exception e) {
                System.debug('############### error with cleanup of outdated sObjectApiName:' + sObjectApiName);
            }
        }
    }

    public static void setCurrentVersion(){
        List<Config_Version__c> configVersions = [SELECT Id, CPQ_Version__c FROM Config_Version__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()];
        if (!configVersions.isEmpty()) {
            Config_Version__c configVersion = configVersions.get(0);
            for (String sObjectApiName : CPQ_SOBJECT_API_NAMES) {
                setVersion(CPQ_QUERY_STRING_BEGIN + sObjectApiName, configVersion.CPQ_Version__c, 'CPQ_Config_Version__c');
            }
            for (String sObjectApiName : NON_CPQ_SOBJECT_API_NAMES) {
                setVersion(NON_CPQ_QUERY_STRING_BEGIN + sObjectApiName, configVersion.CPQ_Version__c, 'Config_Version__c');
            }
        }
    }

    private static void setVersion(String queryString, Decimal version, String versionFieldName){
        SBQQ.TriggerControl.disable();
        List<sObject> sobjectList = Database.query(queryString);
        for (sObject obj : sobjectList) {
            obj.put(versionFieldName, version);
            if (obj.get('Load_Id__c') == null || obj.get('Load_Id__c') == '') {
                obj.put('Load_Id__c', obj.get('Id'));
            }
        }
        update sobjectList;
    }

    public static void incrementVersion(){
        List<Config_Version__c> configVersions = [SELECT Id, CPQ_Version__c, SetupOwnerId FROM Config_Version__c WHERE SetupOwnerId = :UserInfo.getOrganizationId()];
        Config_Version__c configVersion = new Config_Version__c(CPQ_Version__c = 1, SetupOwnerId = UserInfo.getOrganizationId(), Load_Id__c = 'aAm4E0000004FZ1SAM');
        if (!configVersions.isEmpty()) {
            configVersion = configVersions.get(0);
            configVersion.CPQ_Version__c++;
        }
        upsert configVersion;
    }
}