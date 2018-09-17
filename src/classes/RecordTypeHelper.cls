public without sharing class RecordTypeHelper {

    public static final String CASE_SOBJECT = 'Case';
    public static final String OPPORTUNITY_SOBJECT = 'Opportunity';
    public static final String SBQQ_QUOTE_SOBJECT = 'SBQQ__Quote__c';
    public static final String EVENT_SOBJECT = 'Event';

    public class RecordTypeException extends Exception {
    }

    private static Map<String, Map<String, Id>> sObjectToRecordTypes = new Map<String, Map<String, Id>>();
    private static Map<String, RecordType> recordTypesMap = new Map<String, RecordType>();

    static {
        List<RecordType> recordTypes = [
                SELECT Id, DeveloperName, SObjectType
                FROM RecordType
                WHERE IsActive = TRUE
        ];
        for (RecordType rt : recordTypes) {
            recordTypesMap.put(rt.SObjectType + '-' + rt.DeveloperName, rt);

            if (!sObjectToRecordTypes.containsKey(rt.SObjectType)) {
                sObjectToRecordTypes.put(rt.SObjectType, new Map<String, Id>());
            }
            sObjectToRecordTypes.get(rt.SObjectType).put(rt.DeveloperName, rt.Id);
        }
    }

    public static List<RecordType> getRecordTypesForSObject(String sObjectName) {
        List<RecordType> output = new List<RecordType>();
        for (String key : recordTypesMap.keySet()) {
            if (key.startsWith(sObjectName + '-')) {
                output.add(recordTypesMap.get(key));
            }
        }
        return output;
    }

    public static Id getRtIdByDeveloperName(String sObjectName, String developerName) {
        if (!sObjectToRecordTypes.containsKey(sObjectName)) {
            throw new RecordTypeException('RecordType for SObject "' + sObjectName + '" does not exist.');
        }
        Map<String, Id> devNameToRecordTypeId = sObjectToRecordTypes.get(sObjectName);
        if (!devNameToRecordTypeId.containsKey(developerName)) {
            throw new RecordTypeException('RecordType with DeveloperName: "' + developerName + '" does not exist for object "' + sObjectName + '".');
        }
        return devNameToRecordTypeId.get(developerName);
    }

    public static Id getCaseRtIdByDeveloperName(String developerName) {
        return getRtIdByDeveloperName(CASE_SOBJECT, developerName);
    }

    public static Id getSbqqQuoteRtIdByDeveloperName(String developerName) {
        return getRtIdByDeveloperName(SBQQ_QUOTE_SOBJECT, developerName);
    }

    public static Id getOpportunityRtIdByDeveloperName(String developerName) {
        return getRtIdByDeveloperName(OPPORTUNITY_SOBJECT, developerName);
    }

    public static void setRTByDeveloperNameField(SObject obj, String rtDeveloperNameField) {
        Id rtId = getRtIdByDeveloperName(obj.getSObjectType().getDescribe().name, rtDeveloperNameField);
        if (rtId != null) {
            obj.put('RecordTypeId', rtId);
        }
    }

    public static void setRTByDeveloperNameField(List<SObject> objects, String rtDeveloperNameField) {
        for (SObject obj : objects) {
            if(obj.get(rtDeveloperNameField)!=null) {
                setRTByDeveloperNameField(obj, obj.get(rtDeveloperNameField).toString());
            }
        }
    }

}