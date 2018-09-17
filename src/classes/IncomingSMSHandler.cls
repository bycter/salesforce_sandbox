public with sharing class IncomingSMSHandler {

    public IncomingSMSHandler() {
    }

    //Make validation on Incoming SMS message text
    public static void getConfirmationAction(List<smagicinteract__Incoming_SMS__c> incSMS) {
        List<String> contactConfirmed = new List<String>();
        List<String> contactCanceled = new List<String>();
        List<String> contactUnidentified = new List<String>();
        for (smagicinteract__Incoming_SMS__c inc : incSMS) {
            if (inc.smagicinteract__SMS_Text__c != null && inc.smagicinteract__SMS_Text__c.containsIgnoreCase('Yes')) {
                contactConfirmed.add(inc.Mobile_Number_Formatted__c);
            } else if (inc.smagicinteract__SMS_Text__c != null && inc.smagicinteract__SMS_Text__c.containsIgnoreCase('No')) {
                contactCanceled.add(inc.Mobile_Number_Formatted__c);
            } else {
                contactUnidentified.add(inc.Mobile_Number_Formatted__c);
            }
        }
        onIncSMSStatusAction(contactConfirmed, Label.Viewing_SMS_Yes);
        onIncSMSStatusAction(contactCanceled, Label.Viewing_SMS_No);
        onIncSMSStatusAction(contactUnidentified, 'Unidentified');
    }

    private static void onIncSMSStatusAction(List<String> mobiles, String actionParam) {
        List<SObject> leadsAndContacts = obtainLeadsAndContactsByMobile(mobiles);
        List<Event> viewList = getBookedViewingList(SObjectUtils.getIdSetFromObjects(leadsAndContacts, 'Id'));
        for (Event view : viewList) {
            if (actionParam == Label.Viewing_SMS_Yes || actionParam == Label.Viewing_SMS_No) {
                view.Status__c = actionParam;
                view.Status_Updated_By_Customer__c = true;
            }
        }
        if (actionParam == Label.Viewing_SMS_Yes || actionParam == Label.Viewing_SMS_No) {
            try {
                Database.update(viewList);
            } catch (Exception ex) {
                System.debug(ex.getMessage());
            }
            createCancelTask(viewList);
        } else {
            String errorType = 'Unidentified sms messages';
            errorSalesNotification(viewList, errorType);
        }
    }

    private static List<SObject> obtainLeadsAndContactsByMobile(List<String> mobiles) {
        List<SObject> leadsAndContacts = new List<Sobject>();
        leadsAndContacts.addAll([SELECT MobilePhone FROM Contact WHERE MobilePhone IN :mobiles]);
        leadsAndContacts.addAll([SELECT MobilePhone FROM Lead WHERE MobilePhone IN :mobiles]);
        return leadsAndContacts;
    }

    //Assign tasks on Viewing owner if SMS of Viewing has corrupted data
    private static void errorSalesNotification(List<Event> missingView, String errorType) {
        List<Task> taskList = new List<Task>();
        for (Event view : missingView) {
            if (errorType == 'Unidentified sms messages') {
                String taskType = 'Incorrect SMS answer';
                Task newTask = getTaskByType(view, taskType);
                taskList.add(newTask);
            }
        }
        Database.insert(taskList);
    }

    //Create task according to cancelled or failed process type
    private static Task getTaskByType(Event view, String taskType) {
        return new Task(
                WhoId = view.WhoId,
                Subject = taskType,
                Priority = 'High',
                Status = 'Open',
                OwnerId = view.OwnerId,
                Viewing_Id__c = view.Id,
                Viewing_Name__c = view.Subject
        );
    }

    private static void createCancelTask(List<Event> viewList) {
        List<Task> taskList = new List<Task>();
        for (Event view : viewList) {
            if (view.Status__c == 'Cancelled') {
                String taskType = 'Viewing Cancelled ' + view.Subject;
                Task newTask = getTaskByType(view, taskType);
                taskList.add(newTask);
            }
        }
        Database.insert(taskList);
    }

    private static List<Event> getBookedViewingList(Set<Id> objectIdList) {
        Id recordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Viewing').getRecordTypeId();
        return [
                SELECT Id, Status__c, Reminder__c, OwnerId, WhoId, Subject
                FROM Event
                WHERE WhoId IN :objectIdList
                AND Status__c = 'Booked'
                AND Status_Updated_By_Customer__c = false
                AND IsChild = false
                AND RecordTypeId = :recordTypeId
                AND StartDateTime >= TODAY
                LIMIT 10000
        ];
    }
}