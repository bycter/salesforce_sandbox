public class CustomDesignCase {

    public static Id getDesignRecordType() {
        Id designRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Design').getRecordTypeId();
        return designRecordTypeId;
    }

    public static Id getFitOutDesignRecordType() {
        Id designFitOutRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Fit Out Design').getRecordTypeId();
        return designFitOutRecordTypeId;
    }

    public static Id getDesignTeamQueue() {
        Id designTeamId;
        List<Group> queueList = [SELECT Id FROM Group WHERE DeveloperName = 'Design_Team' AND Type = 'Queue'];
        if (queueList.size() > 0) {
            designTeamId = queueList.get(0).Id;
        }
        return designTeamId;
    }

    public String getQuoteId() {
        return ApexPages.currentPage().getParameters().get('QuoteId');
    }

    public Boolean getHaveErrors() {
        Boolean haveErrors = false;
        Id quoteId = getQuoteId();
        String errFitOut = 'Please add a Fit Out product to the quote to create a design case';
        String errInventory = 'Please, select Inventory (Suite) first!';
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        quoteLines = [
                SELECT Id, Suite_Inventory__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND SBQQ__ProductCode__c = 'FitOut'
        ];
        if (quoteLines.size() > 0) {
            if (quoteLines.get(0).Suite_Inventory__c == null) {
                haveErrors = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errInventory));
            }
        } else {
            haveErrors = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, errFitOut));
        }
        return haveErrors;
    }

    public String getCaseId() {
        Id caseId = null;
        Id quoteId = getQuoteId();
        List<Id> recordTypeIds = new List<Id>();
        recordTypeIds.add(getDesignRecordType());
        recordTypeIds.add(getFitOutDesignRecordType());
        List<Case> cases = [
                SELECT Id
                FROM Case
                WHERE Quote__c = :quoteId
                AND RecordTypeId IN :recordTypeIds
        ];
        if (cases.size() > 0) {
            caseId = cases.get(0).Id;
        }
        return caseId;
    }

    @AuraEnabled
    public static CreateDesignCase getCaseParams(Id quoteId) {
        Id quoteLineId = null;
        Id opportunityId = null;
        Id accountId = null;
        Id inventoryId = null;
        List<SBQQ__QuoteLine__c> quoteLines = [
                SELECT Id,
                    Suite_Inventory__c, 
                    SBQQ__Quote__r.SBQQ__Opportunity2__r.AccountId
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND SBQQ__ProductCode__c = 'FitOut'
        ];
        if (quoteLines.size() > 0) {
            quoteLineId = quoteLines.get(0).Id;
            opportunityId = quoteLines.get(0).SBQQ__Quote__r.SBQQ__Opportunity2__c;
            accountId = quoteLines.get(0).SBQQ__Quote__r.SBQQ__Opportunity2__r.AccountId;
            inventoryId = quoteLines.get(0).Suite_Inventory__c;
        }

        CreateDesignCase createCase = new CreateDesignCase();
        createCase.quoteId = quoteId;
        createCase.quoteLineId = quoteLineId;
        createCase.recordTypeId = getDesignRecordType();
        createCase.accountId = accountId;
        createCase.opportunityId = opportunityId;
        createCase.inventoryId = inventoryId;
        createCase.ownerId = getDesignTeamQueue();
        return createCase;
    }

    public class CreateDesignCase {
        @AuraEnabled
        public String quoteId { get; set; }
        @AuraEnabled
        public String quoteLineId { get; set; }
        @AuraEnabled
        public String recordTypeId { get; set; }
        @AuraEnabled
        public String accountId { get; set; }
        @AuraEnabled
        public String opportunityId { get; set; }
        @AuraEnabled
        public String inventoryId { get; set; }
        @AuraEnabled
        public String ownerId { get; set; }
    }
}