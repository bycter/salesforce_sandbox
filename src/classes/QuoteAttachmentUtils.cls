public class QuoteAttachmentUtils {

    public static void associateAttachmentFromQuoteDocumentsWithRelatedContract(List<Attachment> attachments) {
        Map<Id, Attachment> parentIdAttachmentMap = filterAttachmentsByParentObject(attachments, SBQQ__QuoteDocument__c.getSObjectType());
        //create map id-QuoteDocuments with necessary conditions
        Map<Id, SBQQ__QuoteDocument__c> idsByDocuments = new Map<Id, SBQQ__QuoteDocument__c>([
                SELECT Id, SBQQ__Quote__r.Contract__c, SBQQ__SignatureStatus__c,
                        SBQQ__QuoteTemplate__r.Update_Quote_Status__c
                FROM SBQQ__QuoteDocument__c
                WHERE Id = :parentIdAttachmentMap.keySet()
                AND SBQQ__SignatureStatus__c = 'Completed'
                AND SBQQ__Quote__r.Contract__c != null
                AND SBQQ__QuoteTemplate__r.Update_Quote_Status__c != false
        ]);
        //copy the attachment from SBQQ__QuoteDocument__c in to Contract
        copyAttachedDocuments(parentIdAttachmentMap, getQuoteDocToContractIdMap(idsByDocuments.values()));
    }

    public static void copyAttachmentFromQuoteDocumentToSecureObject(List<Attachment> attachments) {
        Map<Id, Attachment> parentIdAttachmentMap = filterAttachmentsByParentObject(attachments, SBQQ__QuoteDocument__c.getSObjectType());
        cleanExistingDocuments(parentIdAttachmentMap);
        copyAttachedDocuments(parentIdAttachmentMap, getQuoteDocToCustomerConfDocMap(parentIdAttachmentMap.keySet()));
    }

    private static Map<Id, Attachment> filterAttachmentsByParentObject(List<Attachment> attachments, SObjectType thetype) {
        Map<Id, Attachment> parentIdAttachmentMap = new Map<Id, Attachment>();
        for (Attachment attachment : attachments) {
            if (attachment.ParentId.getSObjectType() == thetype) {
                parentIdAttachmentMap.put(attachment.ParentId, attachment);
            }
        }
        return parentIdAttachmentMap;
    }

    private static void copyAttachedDocuments(Map<Id, Attachment> parentIdAttachmentMap, Map<Id, Id> attachmentIdsMap) {
        List<Attachment> newAttachments = new List<Attachment>();
        for (Attachment attachment : parentIdAttachmentMap.values()) {
            if (attachmentIdsMap.containsKey(attachment.ParentId)) {
                Attachment newFile = attachment.clone();
                newFile.ParentId = attachmentIdsMap.get(attachment.ParentId);
                newAttachments.add(newFile);
            }
        }
        insert newAttachments;
    }

    private static void cleanExistingDocuments(Map<Id, Attachment> parentIdAttachmentMap) {
        Map<Id, Customer_Confidential_Documentation__c> secureObjectsMap = new Map<Id, Customer_Confidential_Documentation__c>([SELECT SBQQ_Quote_Document__c FROM Customer_Confidential_Documentation__c WHERE SBQQ_Quote_Document__c IN :parentIdAttachmentMap.keySet()]);
        List<Attachment> attachments = [SELECT Name, ParentId FROM Attachment WHERE ParentId IN :secureObjectsMap.keySet()];
        List<Attachment> attachmentsForDelete = new List<Attachment>();
        for ( Attachment theAttachment : attachments ) {
            Id relatedQuoteDocumentId = secureObjectsMap.get(theAttachment.ParentId).SBQQ_Quote_Document__c;
            if ( parentIdAttachmentMap.get(relatedQuoteDocumentId).Name == theAttachment.Name ) {
                attachmentsForDelete.add(theAttachment);
            }
        }
        delete attachmentsForDelete;
    }

    private static Map<Id, Id> getQuoteDocToContractIdMap(List<SBQQ__QuoteDocument__c> documents) {
        Map<Id, Id> attachmentIdsMap = new Map<Id, Id>();
        for ( SBQQ__QuoteDocument__c theDocument : documents ) {
            attachmentIdsMap.put(theDocument.Id, theDocument.SBQQ__Quote__r.Contract__c);
        }
        return attachmentIdsMap;
    }

    private static Map<Id, Id> getQuoteDocToCustomerConfDocMap(Set<Id> quoteDocumentIds) {
        Set<Id> servicedQuoteRecordTypeIds = SBQQ_QuoteService.getServicedRecordTypeIds();
        Set<Id> virtualQuoteRecordTypeIds = SBQQ_QuoteService.getVirtualRecordTypeIds();
        List<Customer_Confidential_Documentation__c> confDocuments = [SELECT SBQQ_Quote_Document__c
                                                                      FROM Customer_Confidential_Documentation__c
                                                                      WHERE SBQQ_Quote_Document__c IN :quoteDocumentIds
                                                                            AND (SBQQ_Quote_Document__r.SBQQ__Quote__r.RecordTypeId IN :servicedQuoteRecordTypeIds
                                                                                OR SBQQ_Quote_Document__r.SBQQ__Quote__r.RecordTypeId IN :virtualQuoteRecordTypeIds)
        ];
        Map<Id, Id> attachmentIdsMap = new Map<Id, Id>();
        for ( Customer_Confidential_Documentation__c confDoc : confDocuments ) {
            attachmentIdsMap.put(confDoc.SBQQ_Quote_Document__c, confDoc.Id);
        }
        return attachmentIdsMap;
    }

}