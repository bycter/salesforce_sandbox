public with sharing class CpqObjectsTransformer {
    private static final String CPQ_PREFIX = 'SBQQ__';
    private static final Set<String> SYSTEM_FIELDS = new Set<String>{
            'id', 'ownerid', 'isdeleted', 'createddate', 'createdbyid', 'lastmodifieddate', 'lastmodifiedbyid', 'systemmodstamp', 'lastvieweddate', 'lastreferenceddate'
    };

    public static SObject populateCPQObject(SObject preCpqObject, SObject cpqObject) {
        for (String fieldName : cpqObject.getSObjectType().getDescribe().fields.getMap().keySet()) {

            if (SYSTEM_FIELDS.contains(fieldName) || preCpqObject.get(fieldName.removeStartIgnoreCase(CPQ_PREFIX)) == null) {
                continue;
            }
            //populate each field
            cpqObject.put(fieldName, preCpqObject.get(fieldName.removeStartIgnoreCase(CPQ_PREFIX)));
        }

        return cpqObject;
    }
}