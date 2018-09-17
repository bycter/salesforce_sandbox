public with sharing class CodaCompanyTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        RecordTypeHelper.setRTByDeveloperNameField(Trigger.new, 'RecordTypeDeveloperName__c');
    }
}