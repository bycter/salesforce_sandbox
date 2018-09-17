/**
 * @description Class contains general functionality for Customer Confidential Documentation object
 */
public with sharing class CustomerConfidentialDocumentationService {

    @TestVisible
    private static final String DEFAULT_VALUE_FOR_COLLECTIONS_FILE_SEQUENCE_NUMBER = '0N';
    private static final String DD_FORM_FIELD_PREFIX = 'DDF_';

    private static final Map<String, List<String>> DD_FORM_FIELDS_MAP = new Map<String, List<String>>{
            'Name_Of_Account_Holder__c' => new List<String>{
                    'Account_Name_1__c', 'Account_Name_2__c'
            },
            'Bank_Building_Society_Account_Number__c' => new List<String>{
                    'Acc_Num_1__c', 'Acc_Num_2__c', 'Acc_Num_3__c', 'Acc_Num_4__c', 'Acc_Num_5__c', 'Acc_Num_6__c', 'Acc_Num_7__c', 'Acc_Num_8__c'
            },
            'Branch_Sort_Code__c' => new List<String>{
                    'Branch_Sort_Code_1__c', 'Branch_Sort_Code_2__c', 'Branch_Sort_Code_3__c', 'Branch_Sort_Code_4__c', 'Branch_Sort_Code_5__c', 'Branch_Sort_Code_6__c'
            },
            'Name_and_Full_Postal_Address_Of_Bank__c' => new List<String>{
                    'Bank_Name__c', 'Address_1__c', 'Address_2__c', 'Postal_Code__c'
            },
            'Reference__c' => new List<String>{
                    'Reference__c'
            }
    };

    /**
     * @description Moves confidential fields from SBQQ Quote Document object to secure object
     */
    public void moveDirectDebitFormFieldsToSecureObject(List<SBQQ__QuoteDocument__c> signedDocuments) {
        List<Customer_Confidential_Documentation__c> secureRecords = new List<Customer_Confidential_Documentation__c>();
        Set<Id> quoteIds = SObjectUtils.getIdSetFromObjects(signedDocuments, 'SBQQ__Quote__c');
        Map<Id, SBQQ__Quote__c> quotes = new Map<Id, SBQQ__Quote__c>([
                SELECT Id, Property__c, Property__r.Company__c
                FROM SBQQ__Quote__c
                WHERE Id IN :quoteIds
        ]);
        for (SBQQ__QuoteDocument__c theDocument : signedDocuments) {
            Customer_Confidential_Documentation__c secureRecord = new Customer_Confidential_Documentation__c();
            secureRecord.Account__c = theDocument.Account_Id__c;
            secureRecord.SBQQ_Quote_Document__c = theDocument.Id;
            secureRecord.Collections_File_Sequence_Number__c = DEFAULT_VALUE_FOR_COLLECTIONS_FILE_SEQUENCE_NUMBER;
            secureRecord.Direct_Debit_Signature__c = theDocument.SBQQ__PrimaryContactId__c;
            if (quotes.containsKey(theDocument.SBQQ__Quote__c)) {
                SBQQ__Quote__c quote = quotes.get(theDocument.SBQQ__Quote__c);
                secureRecord.Legal_Entity__c = quote.Property__c != null ? quote.Property__r.Company__c : null;
            }
            for (String fieldName : DD_FORM_FIELDS_MAP.keySet()) {
                String fieldValue = '';
                for (String documentField : DD_FORM_FIELDS_MAP.get(fieldName)) {
                    if (theDocument.get(DD_FORM_FIELD_PREFIX + documentField) != null) {
                        fieldValue += theDocument.get(DD_FORM_FIELD_PREFIX + documentField);
                        fieldValue += fieldName == 'Name_Of_Account_Holder__c' ? ' ' : '';
                        fieldValue += fieldName == 'Name_and_Full_Postal_Address_Of_Bank__c' ? '\n' : '';
                        secureRecord.put(DD_FORM_FIELD_PREFIX + documentField, theDocument.get(DD_FORM_FIELD_PREFIX + documentField));
                    }
                    theDocument.put(DD_FORM_FIELD_PREFIX + documentField, null);
                }
                secureRecord.put(fieldName, fieldValue);
            }
            secureRecord.Date_Signed__c = theDocument.SBQQDS__SignedDate__c;
            secureRecords.add(secureRecord);
        }
        insert secureRecords;
    }

    /**
     * @description Compiles separate fields from DD Form into consolidated once
     */
    public void updateDirectDebitFormCompiledFields(List<Customer_Confidential_Documentation__c> signedForms) {
        for (Customer_Confidential_Documentation__c ddForm : signedForms) {
            for (String fieldName : DD_FORM_FIELDS_MAP.keySet()) {
                String fieldValue = '';
                for (String documentField : DD_FORM_FIELDS_MAP.get(fieldName)) {
                    if (ddForm.get(DD_FORM_FIELD_PREFIX + documentField) != null) {
                        fieldValue += ddForm.get(DD_FORM_FIELD_PREFIX + documentField);
                        fieldValue += fieldName == 'Name_Of_Account_Holder__c' ? ' ' : '';
                        fieldValue += fieldName == 'Name_and_Full_Postal_Address_Of_Bank__c' ? '\n' : '';
                    }
                    ddForm.put(fieldName, fieldValue);
                }
            }
        }
    }
}