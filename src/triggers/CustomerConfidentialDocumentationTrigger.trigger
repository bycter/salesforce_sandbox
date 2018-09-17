trigger CustomerConfidentialDocumentationTrigger on Customer_Confidential_Documentation__c (before insert, before update, after update) {
    new CustomerConfDocumentationTriggerHandler().run();
}