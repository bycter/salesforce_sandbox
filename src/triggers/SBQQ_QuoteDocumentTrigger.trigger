trigger SBQQ_QuoteDocumentTrigger on SBQQ__QuoteDocument__c (before insert, after insert, before update, after update) {
    new SBQQ_QuoteDocumentTriggerHandler().run();
}