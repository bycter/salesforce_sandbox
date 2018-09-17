public class SObjectUtils {
    /**
     * Get Ids from objects using field 
     */
    public static Set<Id> getIdSetFromObjects(List<SObject> objects, String fieldApiName) {
        if (fieldApiName.equalsIgnoreCase('Id')) {
            return new Map<Id, SObject>(objects).keySet();
        }

        Set<Id> ids = new Set<Id>();
        for (SObject theObject : objects) {
            ids.add(getIdFromObject(theObject, fieldApiName));
        }
        ids.remove(null);
        return ids;
    }

    public static Map<Id, List<SObject>> getIdMapFromObjects(List<SObject> objects, String fieldApiName) {
        Map<Id, List<SObject>> maps = new Map<Id, List<SObject>>();
        for (SObject theObject : objects) {
            Id objId = getIdFromObject(theObject, fieldApiName);
            if (objId != null) {
                if (maps.containsKey(objId)) {
                    maps.get(objId).add(theObject);
                } else {
                    maps.put(objId, new List<SObject>{
                            theObject
                    });
                }
            }
        }
        return maps;
    }

    public static Id getIdFromObject(SObject theObject, String fieldApiName) {
        Object theValue = theObject.get(fieldApiName);
        return theValue != null ? (Id) theValue : null;
    }

    /**
     *  Get list of modified objects by defined list of modified fields.
     */
    public static List<SObject> getModifiedObjects(List<String> fields, List<SObject> records, Map<Id, SObject> oldRecordsMap) {
        List<SObject> results = new List<SObject>();

        if (records == null || records.isEmpty()) {
            return results;
        }

        if (oldRecordsMap == null || oldRecordsMap.isEmpty()) {
            return records;
        }

        for (SObject record : records) {
            Id recordId = record.Id;

            if (!oldRecordsMap.containsKey(recordId)) {
                results.add(record);
                continue;
            }

            SObject oldRecord = oldRecordsMap.get(recordId);
            for (String fieldName : fields) {
                if (record.get(fieldName) != oldRecord.get(fieldName)) {
                    results.add(record);
                }
            }
        }
        return results;
    }

    /**
     *   Filter records by record type.
     */
    public static List<SObject> filterRecordsByRecordType(List<SObject> records, Set<Id> recordTypeIds) {
        List<SObject> result = new List<SObject>();
        if (records != null) {
            for (SObject record : records) {
                if (recordTypeIds.contains((Id) record.get('RecordTypeId'))) {
                    result.add(record);
                }
            }
        }
        return result;
    }

    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
        List<String> result = new List<String>();
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectApiName).newSObject().getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<Schema.PicklistEntry> picklistVvalues = fieldMap.get(fieldApiName).getDescribe().getPickListValues();
        for (Schema.PicklistEntry entry : picklistVvalues) {
            result.add(entry.getValue());
        }
        return result;
    }

    public static List<String> getFieldsApiNames(Schema.sObjectType objectType) {
        DescribeSObjectResult describeResult = objectType.getDescribe();
        return new List<String>(describeResult.fields.getMap().keySet());
    }
}