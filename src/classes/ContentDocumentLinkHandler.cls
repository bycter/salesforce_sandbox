public class ContentDocumentLinkHandler extends TriggerHandler {

    //Salesforce CPQ supports only PDF format for Additional Documents
    private static final Set<String> sharedFileExtensions = new Set<String>{
            'pdf'
    };

    public override void afterInsert() {
        associateCaseDocumentsWithRelatedObjects((List<ContentDocumentLink>) Trigger.new);
    }

    private void associateCaseDocumentsWithRelatedObjects(List<ContentDocumentLink> documents) {
        //Associate case documents with related quote
        associateDocumentsWithQuote(documents);
        //Associate case documents with related inventory
        associateDocumentsWithInventory(documents);
        //Associate case documents with related account
        associateDocumentsWithAccount(documents);
    }

    private void associateDocumentsWithQuote(List<ContentDocumentLink> documents) {
        List<SBQQ__RelatedContent__c> quoteDocuments = new List<SBQQ__RelatedContent__c>();
        for (ContentDocumentLink cdl : documents) {
            if (isCase(cdl.LinkedEntityId)) {
                Case entityCase = [SELECT Id, Quote__c, RecordTypeId FROM Case WHERE Id = :cdl.LinkedEntityId];
                ContentDocument document = [SELECT Id, FileExtension, Title FROM ContentDocument WHERE Id = :cdl.ContentDocumentId];
                if (isFitOutDesignCase(entityCase) && String.isNotBlank(entityCase.Quote__c) && sharedFileExtensions.contains(document.FileExtension)) {
                    quoteDocuments.add(new SBQQ__RelatedContent__c(
                            SBQQ__ExternalId__c = document.Id, 
                            SBQQ__Quote__c = entityCase.Quote__c, 
                            Name = document.Title)
                    );
                }
            }
        }
        if (!quoteDocuments.isEmpty()) {
            insert quoteDocuments;
        }
    }

    private void associateDocumentsWithInventory(List<ContentDocumentLink> documents) {
        List<ContentDocumentLink> inventoryDocuments = new List<ContentDocumentLink>();
        for (ContentDocumentLink cdl : documents) {
            if (isCase(cdl.LinkedEntityId)) {
                Case entityCase = [SELECT Id, Quote__c, RecordTypeId, Inventory__c FROM Case WHERE Id = :cdl.LinkedEntityId];
                if (isFitOutDesignCase(entityCase) && String.isNotBlank(entityCase.Inventory__c)) {
                    inventoryDocuments.add(new ContentDocumentLink(ContentDocumentId = cdl.ContentDocumentId, LinkedEntityId = entityCase.Inventory__c, ShareType = 'V'));
                }
            }
        }
        if (!inventoryDocuments.isEmpty()) {
            insert inventoryDocuments;
        }
    }

    private void associateDocumentsWithAccount(List<ContentDocumentLink> documents) {
        List<ContentDocumentLink> accountDocuments = new List<ContentDocumentLink>();
        for (ContentDocumentLink cdl : documents) {
            if (isCase(cdl.LinkedEntityId)) {
                Case entityCase = [SELECT Id, AccountId, RecordTypeId FROM Case WHERE Id = :cdl.LinkedEntityId];
                if (isFitOutDesignCase(entityCase) && String.isNotBlank(entityCase.AccountId)) {
                    accountDocuments.add(new ContentDocumentLink(ContentDocumentId = cdl.ContentDocumentId, LinkedEntityId = entityCase.AccountId, ShareType = 'V'));
                }
            }
        }
        if (!accountDocuments.isEmpty()) {
            insert accountDocuments;
        }
    }

    private Boolean isFitOutDesignCase(Case entityCase) {
        RecordType recordType = [SELECT Id, DeveloperName FROM RecordType WHERE Id = :entityCase.RecordTypeId];
        return recordType.DeveloperName == 'Fit_Out_Design';
    }

    private Boolean isCase(Id entityId) {
        return String.isNotBlank(entityId) && String.valueOf(entityId).startsWith('500');
    }
}