public without sharing class ValidateAdHocRevenueCtrl {

    public static final String VALUES_NOT_FOUND_ERROR_MSG = 'Next fields values not found in an existing records on the corresponding objects: ';
    public static final String RECORD_NOT_FOUND_ERROR_MSG = 'Record not found!';

    @AuraEnabled
    public static void validateFields(String recordId) {
        Ad_hoc_Revenue__c adHocRevenue;
        List<Ad_hoc_Revenue__c> adHocRevenues = [
                SELECT Id,
                        Legal_Entity__c,
                        Tax_Code__c
                FROM Ad_hoc_Revenue__c
                WHERE Id = :recordId
        ];
        if (!adHocRevenues.isEmpty()) {
            adHocRevenue = adHocRevenues.get(0);
        } else {
            String errorMsg = RECORD_NOT_FOUND_ERROR_MSG;
            AuraHandledException e = new AuraHandledException(errorMsg);
            e.setMessage(errorMsg);
            throw e;
        }
        validateMandatoryFields(adHocRevenue);
        validateLookups(adHocRevenue);
    }

    public static void validateMandatoryFields(Ad_hoc_Revenue__c adHocRevenue) {
        Savepoint sp = Database.setSavepoint();
        Database.SaveResult sr = Database.update(new Ad_hoc_Revenue__c(Id = adHocRevenue.Id, Is_Validation_Enable__c = true), false);
        if (!sr.isSuccess()) {
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Ad_hoc_Revenue__c.fields.getMap();
            Map<String, Set<String>> errorMsgToFields = new Map<String, Set<String>>();
            for (Database.Error err : sr.getErrors()) {
                if (StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION == err.getStatusCode()) {
                    String fieldLabel = err.getFields().isEmpty() ? null : fieldMap.get(err.getFields().get(0)).getDescribe().getLabel();
                    if (errorMsgToFields.containsKey(err.getMessage()) && fieldLabel != null) {
                        errorMsgToFields.get(err.getMessage()).add(fieldLabel);
                    } else {
                        errorMsgToFields.put(err.getMessage(), fieldLabel != null ? new Set<String>{
                                fieldLabel
                        } : new Set<String>());
                    }
                }
            }
            if (!errorMsgToFields.isEmpty()) {
                String errorMsg = '';
                for (String em : errorMsgToFields.keySet()) {
                    List<String> fieldsLabels = new List<String>();
                    fieldsLabels.addAll(errorMsgToFields.get(em));
                    errorMsg += em + (fieldsLabels.isEmpty() ? '' : ': ' + String.join(fieldsLabels, ', ') + '\n');
                }
                AuraHandledException e = new AuraHandledException(errorMsg);
                e.setMessage(errorMsg);
                throw e;
            }
        }
        Database.rollback(sp);
    }

    private static void validateLookups(Ad_hoc_Revenue__c adHocRevenue) {
        List<String> notMatchedFields = new List<String>();
        if (!isCompanyFound(adHocRevenue.Legal_Entity__c)) {
            notMatchedFields.add(Schema.SObjectType.Ad_hoc_Revenue__c.fields.Legal_Entity__c.getLabel());
        }
        if (!isTaxCodeFound(adHocRevenue.Tax_Code__c)) {
            notMatchedFields.add(Schema.SObjectType.Ad_hoc_Revenue__c.fields.Tax_Code__c.getLabel());
        }
        if (!notMatchedFields.isEmpty()) {
            String errorMsg = VALUES_NOT_FOUND_ERROR_MSG + String.join(notMatchedFields, ', ');
            AuraHandledException e = new AuraHandledException(errorMsg);
            e.setMessage(errorMsg);
            throw e;
        }
    }

    @TestVisible
    private static Boolean isTaxCodeFound(String taxCode) {
        Boolean isFound = false;
        c2g__codaTaxCode__c record = new c2g__codaTaxCode__c();
        List<c2g__codaTaxCode__c> taxCodes = [
                SELECT Id, Name
                FROM c2g__codaTaxCode__c
                WHERE Name = :taxCode
                LIMIT 1
        ];
        if (!taxCodes.isEmpty()) {
            isFound = true;
        }
        return isFound;
    }

    @TestVisible
    private static Boolean isCompanyFound(String companyName) {
        Boolean isFound = false;
        c2g__codaCompany__c company = new c2g__codaCompany__c();
        List<c2g__codaCompany__c> companies = [
                SELECT Id, Name
                FROM c2g__codaCompany__c
                WHERE Name = :companyName
                LIMIT 1
        ];
        if (!companies.isEmpty()) {
            isFound = true;
        }
        return isFound;
    }

}