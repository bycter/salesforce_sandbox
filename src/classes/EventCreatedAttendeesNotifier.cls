public with sharing class EventCreatedAttendeesNotifier {

    @InvocableMethod
    public static void notify(List<Id> eventsIds) {
        List<Event> events = [SELECT Id, Viewing_Conducted_by_User__c FROM Event WHERE Id IN : eventsIds LIMIT 10000];
        List<EventRelation> attendees = [SELECT Id, RelationId, EventId FROM EventRelation WHERE EventId IN : eventsIds AND IsInvitee = true LIMIT 10000];
        EventAttendeesEmailSender sender = new EventAttendeesEmailSender();
        sender.sendOnCreate(events, attendees);
    }

}