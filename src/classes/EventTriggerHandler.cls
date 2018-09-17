public with sharing class EventTriggerHandler extends TriggerHandler {

    public static final String VIEWING_RECORD_TYPE = 'Viewing';

    protected override void beforeInsert() {
        EventUpdateStartDateTime.updateDate((List<Event>) Trigger.new);
    }

    protected override void beforeUpdate() {
        EventUpdateStartDateTime.updateDate((List<Event>) Trigger.new);
    }

    protected override void afterInsert() {
        pushViewingsIntoUsersCalendar((List<Event>) Trigger.new);
    }

    protected override void afterUpdate() {
        pushViewingsIntoUsersCalendar((List<Event>) Trigger.new);
    }

    private void pushViewingsIntoUsersCalendar(List<Event> events) {
        List<Event> viewings = getViewings(events);
        Set<Id> viewingIds = SObjectUtils.getIdSetFromObjects(viewings, 'Id');
        Map<Id, Set<Id>> attendeesIdsByEventIds = getAttendeesIdsByEventIds(viewingIds);
        removeExistingAttendees(attendeesIdsByEventIds);

        List<EventRelation> eventRelations = new List<EventRelation>();
        for (Id eventId : attendeesIdsByEventIds.keySet()) {
            for (Id attendeeId : attendeesIdsByEventIds.get(eventId)) {
                eventRelations.add(new EventRelation(EventId = eventId, RelationId = attendeeId, IsInvitee = true));
            }
        }
        upsert eventRelations;
    }

    private void removeExistingAttendees(Map<Id, Set<Id>> attendeesIdsByEventIds) {
        List<EventRelation> eventRelations = [
                SELECT Id, EventId, RelationId
                FROM EventRelation
                WHERE EventId IN :attendeesIdsByEventIds.keySet() AND IsInvitee = :true
        ];
        for (EventRelation eventRelation : eventRelations) {
            removeAttendee(attendeesIdsByEventIds, eventRelation.EventId, eventRelation.RelationId);
        }
    }

    private void removeAttendee(Map<Id, Set<Id>> attendeesIdsByEventIds, Id eventId, Id attendeeId) {
        if (attendeesIdsByEventIds.containsKey(eventId)) {
            attendeesIdsByEventIds.get(eventId).remove(attendeeId);
        }
    }

    private Map<Id, Set<Id>> getAttendeesIdsByEventIds(Set<Id> eventIds) {
        Map<Id, Set<Id>> attendeesIdsByEventIds = new Map<Id, Set<Id>>();
        List<Event> events = [
                SELECT
                        Id,
                        Property__r.Property_Manager__c,
                        Property__r.Reception__c,
                        Property__r.Serviced_Space_Coordinator__c,
                        Viewing_Conducted_by_User__c,
                        OwnerId
                FROM Event
                WHERE Id IN :eventIds AND IsChild = :false
        ];
        for (Event e : events) {
            Set<Id> attendeesIds = new Set<Id>();
            if (e.Viewing_Conducted_by_User__c != null && e.Viewing_Conducted_by_User__c != e.OwnerId) {
                attendeesIds.add(e.Viewing_Conducted_by_User__c);
            }
            if (e.Property__r.Property_Manager__c != null && e.Property__r.Property_Manager__c != e.OwnerId) {
                attendeesIds.add(e.Property__r.Property_Manager__c);
            }
            if (e.Property__r.Reception__c != null && e.Property__r.Reception__c != e.OwnerId) {
                attendeesIds.add(e.Property__r.Reception__c);
            }
            if (e.Property__r.Serviced_Space_Coordinator__c != null && e.Property__r.Serviced_Space_Coordinator__c != e.OwnerId) {
                attendeesIds.add(e.Property__r.Serviced_Space_Coordinator__c);
            }
            attendeesIdsByEventIds.put(e.Id, attendeesIds);
        }
        return attendeesIdsByEventIds;
    }

    private List<Event> getViewings(List<Event> events) {
        List<Event> viewings = new List<Event>();
        for (Event e : events) {
            if (e.RecordTypeId == RecordTypeHelper.getRtIdByDeveloperName(RecordTypeHelper.EVENT_SOBJECT, VIEWING_RECORD_TYPE)) {
                viewings.add(e);
            }
        }
        return viewings;
    }
}