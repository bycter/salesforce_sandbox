/**
 * @description Controller class for ConvertPotentialContact lightning component
 */
public with sharing class ConvertPotentialContactController {

    @AuraEnabled
    public static Id upsertPotentialContact(Id potentialContactId) {
        if ( String.isBlank(potentialContactId) ) {
            return null;
        }
        Potential_Contact__c potentialContact = [SELECT Account__c, First_Name__c, Last_Name__c, Email__c, Phone__c, Mobile__c, Contact_Preference__c, Contact_Type__c,
                                                        New_First_Name__c, New_Last_Name__c, New_Email__c, New_Phone__c, New_Mobile__c, New_Contact_Preference__c, New_Contact_Type__c,
                                                        SBQQ_Quote__c, SBQQ_Quote__r.Property__c
                                                 FROM Potential_Contact__c
                                                 WHERE Id = :potentialContactId];
        System.debug('potentialContact: ' + potentialContact);
        String firstName = String.isNotBlank(potentialContact.First_Name__c) ? String.escapeSingleQuotes(potentialContact.First_Name__c) : '';
        String lastName = String.isNotBlank(potentialContact.Last_Name__c) ? String.escapeSingleQuotes(potentialContact.New_First_Name__c) : '';
        String query = 'SELECT Contact_Type__c ' +
                       'FROM Contact ' +
                       'WHERE AccountId = \'' + potentialContact.Account__c + '\' AND ' +
                       '((FirstName = \'' + firstName + '\' AND LastName = \'' + lastName + '\' AND Email = \'' + potentialContact.Email__c + '\'';
        if ( String.isNotBlank(potentialContact.Phone__c) ) {
            query += ' AND Phone = \'' + potentialContact.Phone__c + '\'';
        }
        if ( String.isNotBlank(potentialContact.Mobile__c) ) {
            query += ' AND MobilePhone = \'' + potentialContact.Mobile__c + '\'';
        }
        query += ') OR (FirstName = \'' + String.escapeSingleQuotes(potentialContact.New_First_Name__c) + '\' AND LastName = \'' + String.escapeSingleQuotes(potentialContact.New_Last_Name__c) + '\' AND Email = \'' + potentialContact.New_Email__c + '\'';
        if ( String.isNotBlank(potentialContact.New_Phone__c) ) {
            query += ' AND Phone = \'' + potentialContact.New_Phone__c + '\'';
        }
        if ( String.isNotBlank(potentialContact.New_Mobile__c) ) {
            query += ' AND MobilePhone = \'' + potentialContact.New_Mobile__c + '\'';
        }
        query += '))';
        List<Contact> contacts = (List<Contact>)Database.query(query);
        Id externalContactRecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Contact' AND DeveloperName = 'External'].Id;
        Contact contactToUpsert;
        if ( contacts.isEmpty() ) {
            contactToUpsert = new Contact();
        } else {
            contactToUpsert = contacts[0];
        }
        contactToUpsert.AccountId = potentialContact.Account__c;
        contactToUpsert.FirstName = potentialContact.New_First_Name__c;
        contactToUpsert.LastName = potentialContact.New_Last_Name__c;
        contactToUpsert.Email = potentialContact.New_Email__c;
        contactToUpsert.Phone = potentialContact.New_Phone__c;
        contactToUpsert.MobilePhone = potentialContact.New_Mobile__c;
        contactToUpsert.Contact_Preference__c = potentialContact.New_Contact_Preference__c;
        String contactType = String.isBlank(contactToUpsert.Contact_Type__c) ? potentialContact.Contact_Type__c : contactToUpsert.Contact_Type__c;
        contactType = !contactType.containsIgnoreCase(potentialContact.Contact_Type__c) ? contactType + ';' + potentialContact.Contact_Type__c : contactType;
        contactToUpsert.Contact_Type__c = contactType;
        contactToUpsert.RecordTypeId = externalContactRecordTypeId;
        contactToUpsert.Property__c = potentialContact.SBQQ_Quote__r.Property__c;

        Database.UpsertResult result = Database.upsert(contactToUpsert, false);
        if ( !result.isSuccess() ) {
            for ( Database.Error error : result.getErrors() ) {
                if ( error instanceof Database.DuplicateError ) {
                    DataCloud.DuplicateResult dupResult = ((Database.DuplicateError)error).getDuplicateResult();
                    Contact duplicateContact = (Contact)dupResult.getMatchResults()[0].getMatchRecords()[0].getRecord();
                    String duplicateContactLink = '<a href="/' + duplicateContact.Id + '">' + duplicateContact.Name + '</a>';
                    throw new AuraHandledException(duplicateContactLink);
                }
            }
        }

        List<Task> reviewPCTasks = [SELECT Id FROM Task WHERE WhatId = :potentialContactId AND System_Code__c = :TaskService.REVIEW_POTENTIAL_CONTACT_SYSTEM_CODE];
        if ( !reviewPCTasks.isEmpty() ) {
            reviewPCTasks[0].Status = 'Completed';
            update reviewPCTasks[0];
        }

        assignContactToCases(contactToUpsert, potentialContact.SBQQ_Quote__c);

        return contactToUpsert.Id;
    }

    private static void assignContactToCases(Contact contact, Id quoteId) {
        String typeParam = String.isNotBlank(contact.Contact_Type__c) ? contact.Contact_Type__c.toUpperCase(): '';
        Map<String, Set<Id>> recordTypesMap = getRecordTypesToFilter();

        if (recordTypesMap.containsKey(typeParam)) {
            Set<Id> caseRTypesToFilter = recordTypesMap.get(typeParam);
            List<Case> cases = [SELECT Id FROM Case WHERE Quote__c = :quoteId AND RecordTypeId  IN: caseRTypesToFilter];
            for ( Case theCase : cases ) {
                theCase.ContactId = contact.Id;
            }
            update cases;
        }
    }

    private static Map<String, Set<Id>> getRecordTypesToFilter() {
        Map<String, Set<Id>> recordTypesMap = new Map<String, Set<Id>>();

        recordTypesMap.put(
            SBQQ_QuoteConstants.CONTACT_TYPE_LC.toUpperCase(),
            new Set<Id> { RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.LEASE_TRANSACTION_RECORD_TYPE) }
        );

        recordTypesMap.put(
            SBQQ_QuoteConstants.CONTACT_TYPE_ILPC.toUpperCase(),
            new Set<Id> {
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.CONVENTIONAL_ONBOARDING_RECORD_TYPE),
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.SERVICED_SPACE_ONBOARDING_RECORD_TYPE)
            }
        );

        recordTypesMap.put(
            SBQQ_QuoteConstants.CONTACT_TYPE_PMC.toUpperCase(),
            new Set<Id> {
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.DESIGN_RECORD_TYPE),
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.FIT_OUT_DESIGN_RECORD_TYPE),
                RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.BUILDING_CONSTRUCTION_CASE_RECORD_TYPE)
            }
        );

        return recordTypesMap;
    }
}