public with sharing class IncomingSMSFlowAction {

    @InvocableMethod
    public static void incomingSMSFlowAction(List<Id> incSMSId) {
        //This method catch all incoming smsand start notification process to sales managers or update Viewing__c

        List<smagicinteract__Incoming_SMS__c> incSMS = [
                SELECT Id, smagicinteract__Contact__c, smagicinteract__Inbound_Number__c,
                        smagicinteract__Mobile_Number__c, smagicinteract__Sent_By__c, smagicinteract__SMS_Text__c, Mobile_Number_Formatted__c
                FROM smagicinteract__Incoming_SMS__c
                WHERE Id IN :incSMSId
                LIMIT 10000
        ];
        IncomingSMSHandler.getConfirmationAction(incSMS);
    }
}