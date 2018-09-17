/**
 * @description Class contains general functionality related to SBQQ__QuoteDocument__c object
 */
public with sharing class SBQQ_QuoteDocumentService {

    /**
     * @description Returns a map of quoteId => acoountId
     */
    public Map<Id, Id> getRelatedAccountIdsMap(List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<Id, Id> quoteToAccountMap = new Map<Id, Id>();
        for ( SBQQ__QuoteDocument__c quoteDocument : quoteDocuments ) {
            quoteToAccountMap.put(quoteDocument.SBQQ__Quote__c, quoteDocument.Account_Id__c);
        }
        return quoteToAccountMap;
    }

    /**
     * @description Loops through related contacts and populates fields on quote document
     */
    public void populateQuoteDocumentFields(SBQQ__QuoteDocument__c quoteDocument, List<Contact> customerContacts) {
        if ( customerContacts != null ) {
            for ( Contact customerContact : customerContacts ) {
                if ( customerContact != null && String.isNotBlank(customerContact.Contact_Type__c) ) {
                    List<String> contactTypes = customerContact.Contact_Type__c.split(';');
                    for ( String contactType : contactTypes ) {
                        if ( contactType == SBQQ_QuoteConstants.CONTACT_TYPE_LC ) {
                            populateQuoteDocumentFields(quoteDocument, customerContact, SBQQ_QuoteConstants.CONTACT_TYPE_TO_PREFIX_MAP.get(SBQQ_QuoteConstants.CONTACT_TYPE_LC));
                        } else if ( contactType == SBQQ_QuoteConstants.CONTACT_TYPE_PMC ) {
                            populateQuoteDocumentFields(quoteDocument, customerContact, SBQQ_QuoteConstants.CONTACT_TYPE_TO_PREFIX_MAP.get(SBQQ_QuoteConstants.CONTACT_TYPE_PMC));
                        } else if ( contactType == SBQQ_QuoteConstants.CONTACT_TYPE_ILPC ) {
                            populateQuoteDocumentFields(quoteDocument, customerContact, SBQQ_QuoteConstants.CONTACT_TYPE_TO_PREFIX_MAP.get(SBQQ_QuoteConstants.CONTACT_TYPE_ILPC));
                        } else if ( contactType == SBQQ_QuoteConstants.CONTACT_TYPE_OOHC ) {
                            populateQuoteDocumentFields(quoteDocument, customerContact, SBQQ_QuoteConstants.CONTACT_TYPE_TO_PREFIX_MAP.get(SBQQ_QuoteConstants.CONTACT_TYPE_OOHC));
                        } else if ( contactType == SBQQ_QuoteConstants.CONTACT_TYPE_BC ) {
                            populateQuoteDocumentFields(quoteDocument, customerContact, SBQQ_QuoteConstants.CONTACT_TYPE_TO_PREFIX_MAP.get(SBQQ_QuoteConstants.CONTACT_TYPE_BC));
                        }
                    }
                }
            }
        }
    }

    /**
     * @description Updates Fields on parent opportunities based on Document status
     */
    public void updateParentOpportunities(List<SBQQ__QuoteDocument__c> theDocuments) {
        Set<Id> opportunitiesIds = SObjectUtils.getIdSetFromObjects(theDocuments, 'SBQQ__Opportunity__c');
        Map<Id, Opportunity> parentOpportunitiesMap = new Map<Id, Opportunity>([SELECT Id FROM Opportunity WHERE Id IN :opportunitiesIds]);
        List<Opportunity> opportunitiesForUpdate = new List<Opportunity>();
        for ( SBQQ__QuoteDocument__c theDocument : theDocuments ) {
            Opportunity parentOpportunity = parentOpportunitiesMap.get(theDocument.SBQQ__Opportunity__c);
            if ( theDocument.SBQQ__ElectronicSignature__c && theDocument.Signature_Status__c == 'Sent' ) {
                if ( theDocument.Quote_Record_Type__c.startsWith(OpportunityService.CONVENTIONAL_RECORD_TYPE ) ) {
                    parentOpportunity.HOTs_Sent__c = true;
                } else if ( theDocument.Quote_Record_Type__c.startsWith(OpportunityService.SERVICED_RECORD_TYPE) ) {
                    parentOpportunity.LA_Sent__c = true;
                }
                opportunitiesForUpdate.add(parentOpportunity);
            } else if ( theDocument.SBQQ__ElectronicSignature__c && theDocument.Signature_Status__c == 'Completed' ) {
                if ( theDocument.Quote_Record_Type__c.startsWith(OpportunityService.CONVENTIONAL_RECORD_TYPE) || theDocument.Quote_Record_Type__c.startsWith(OpportunityService.VIRTUAL_RECORD_TYPE_NAME) ) {
                    parentOpportunity.HOTs_Signed__c = true;
                } else if ( theDocument.Quote_Record_Type__c.startsWith(OpportunityService.SERVICED_RECORD_TYPE) ) {
                    parentOpportunity.LA_Signed__c = true;
                }
                opportunitiesForUpdate.add(parentOpportunity);
            }
        }
        System.debug('opportunitiesForUpdate: ' + opportunitiesForUpdate);
        update opportunitiesForUpdate;
    }

    /**
     * @description Copies field from contact to corresponding field on Quote Document
     */
    private void populateQuoteDocumentFields(SBQQ__QuoteDocument__c quoteDocument, Contact customerContact, String contactTypePrefix) {
        for ( String fieldName : SBQQ_QuoteConstants.FIELD_NAMES_MAP.keySet() ) {
            quoteDocument.put(contactTypePrefix + '_' + fieldName, customerContact.get(SBQQ_QuoteConstants.FIELD_NAMES_MAP.get(fieldName)));
        }
    }

    /**
     * @description Returns a list of documents where contact information was updated
     */
    public Map<SBQQ__QuoteDocument__c, Set<String>> getDocumentsWithUpdatedContactInfo(Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap, List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<SBQQ__QuoteDocument__c, Set<String>> updatedDocsMap = new Map<SBQQ__QuoteDocument__c, Set<String>>();
        for ( SBQQ__QuoteDocument__c theDocument : quoteDocuments ) {
            SBQQ__QuoteDocument__c oldDocument = oldDocumentsMap.get(theDocument.Id);
            Set<String> updatedContactTypes = getUpdatedContactTypes(oldDocument, theDocument);
            if ( !updatedContactTypes.isEmpty() ) {
                updatedDocsMap.put(theDocument, updatedContactTypes);
            }
        }
        return updatedDocsMap;
    }

    /**
     * @description Returns a map of Account Ids with updated Company Registration Numbers
     */
    public Map<Id, String> getAccountIdsWithUpdatedCompanyNumber(Map<Id, SBQQ__QuoteDocument__c> oldDocumentsMap, List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<Id, String> accountIdToCompanyNumberMap = new Map<Id, String>();
        for ( SBQQ__QuoteDocument__c theDocument : quoteDocuments ) {
            SBQQ__QuoteDocument__c oldDocument = oldDocumentsMap.get(theDocument.Id);
            if ( oldDocument.Company_Registration_Number__c != theDocument.Company_Registration_Number__c ) {
             accountIdToCompanyNumberMap.put(theDocument.Account_Id__c, theDocument.Company_Registration_Number__c);
            }
        }
        return accountIdToCompanyNumberMap;
    }

    /**
     * @description Returns a map of signed documents
     */
    public Map<Id, SBQQ__QuoteDocument__c> getSignedDocumentsMap(List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Map<Id, SBQQ__QuoteDocument__c> signedDocumentsMap = new Map<Id, SBQQ__QuoteDocument__c>();
        for ( SBQQ__QuoteDocument__c theDocument : quoteDocuments ) {
            if ( theDocument.SBQQ__SignatureStatus__c == SBQQ_QuoteConstants.STATUS_SIGNATURE_COMPLETE ) {
                signedDocumentsMap.put(theDocument.Id, theDocument);
            }
        }
        return signedDocumentsMap;
    }

    /**
     * @description Virifies if document signed by Company Director and creates a Reminder if it's not.
     */
    public void verifyIfDocumentsSignedByCompanyDirector(List<SBQQ__QuoteDocument__c> signedDocuments, Map<Id, List<Contact>> companyDirectorsMap) {
        Map<Id, Task> reminderTasksMap = new Map<Id, Task>();
        for ( SBQQ__QuoteDocument__c theDocument : signedDocuments ) {
            theDocument.Signed_By_CD__c = theDocument.Signed_By_CD__c || false;
            if ( companyDirectorsMap.containsKey(theDocument.Account_Id__c) ) {
                for ( Contact theContact : companyDirectorsMap.get(theDocument.Account_Id__c) ) {
                    if ( String.isNotBlank(theDocument.CD_First_Name__c) && String.isNotBlank(theDocument.CD_Last_Name__c) &&
                        theContact.FirstName == theDocument.CD_First_Name__c && theContact.LastName == theDocument.CD_Last_Name__c ) {
                        theDocument.Signed_By_CD__c = true;
                    }
                }
            }
            if ( !theDocument.Signed_By_CD__c ) {
                reminderTasksMap.put(theDocument.SBQQ__Quote__c, TaskService.generateSetupCDTask(theDocument));
            }
        }
        filterExistingReminders(reminderTasksMap);
        insert reminderTasksMap.values();
    }

    /**
     * @description Populates unique document numer based on Quote.Name and related documents counter
     */
    public void populateUniqueDocumentsNumber(List<SBQQ__QuoteDocument__c> quoteDocuments) {
        Set<Id> quoteIds = new Set<Id>();
        for ( SBQQ__QuoteDocument__c quoteDocument : quoteDocuments ) {
            quoteIds.add(quoteDocument.SBQQ__Quote__c);
        }
        Map<Id, SBQQ__Quote__c> quotesMap = new Map<Id, SBQQ__Quote__c>([SELECT Name, Documents_Counter__c FROM SBQQ__Quote__c WHERE Id IN :quoteIds]);
        for ( SBQQ__QuoteDocument__c quoteDocument : quoteDocuments ) {
            SBQQ__Quote__c parentQuote = quotesMap.get(quoteDocument.SBQQ__Quote__c);
            quoteDocument.Unique_Document_Number__c = parentQuote.Name + '-' + (parentQuote.Documents_Counter__c + 1);
        }
    }

    /**
     * @description Returns a list of documents with specified record type
     */
    public List<SBQQ__QuoteDocument__c> getDocumentsWithRecordType(List<SBQQ__QuoteDocument__c> quoteDocuments, String recordTypeName) {
        List<SBQQ__QuoteDocument__c> filterredDocuments = new List<SBQQ__QuoteDocument__c>();
        for ( SBQQ__QuoteDocument__c quoteDocument : quoteDocuments ) {
            if ( quoteDocument.Quote_Record_Type__c.startsWith(recordTypeName) ) {
                filterredDocuments.add(quoteDocument);
            }
        }
        return filterredDocuments;
    }

    /**
     * @description Checks if Customer Contact Fields were updated
     */
    private Set<String> getUpdatedContactTypes(SBQQ__QuoteDocument__c oldDocument, SBQQ__QuoteDocument__c newDocument) {
        Set<String> updatedContactTypes = new Set<String>();
        for ( String fieldPrefix : SBQQ_QuoteConstants.CONTACT_TYPE_TO_PREFIX_MAP.values() ) {
            for ( String fieldName : SBQQ_QuoteConstants.FIELD_NAMES_MAP.keySet() ) {
                if ( oldDocument.get(fieldPrefix + '_' + fieldName) != newDocument.get(fieldPrefix + '_' + fieldName) ) {
                    updatedContactTypes.add(fieldPrefix);
                    break;
                }
            }
        }
        return updatedContactTypes;
    }

    private void filterExistingReminders(Map<Id, Task> reminderTasksMap) {
        List<Task> existingReminders = [SELECT WhatId FROM Task WHERE WhatId IN :reminderTasksMap.keySet() AND System_Code__c =: TaskService.SETUP_CD_SYSTEM_CODE];
        for ( Task reminder : existingReminders ) {
            reminderTasksMap.remove(reminder.WhatId);
        }
    }

}