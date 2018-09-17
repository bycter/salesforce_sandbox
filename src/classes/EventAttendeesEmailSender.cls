public class EventAttendeesEmailSender {

    private List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

    public Messaging.SendEmailResult[] sendOnCreate(List<Event> events, List<EventRelation> attendees) {
        Map<String,Id> templates = getTemplates();
        templates.put('Contact', templates.get(Label.ViewingCreatedContactTemplate));
        templates.put('User', templates.get(Label.ViewingCreatedUserTemplate));
        return send(events, attendees, templates);
    }

    public Messaging.SendEmailResult[] sendOnUpdate(List<Event> events, List<EventRelation> attendees) {
        Map<String,Id> templates = getTemplates();
        templates.put('Contact', templates.get(Label.ViewingUpdatedContactTemplate));
        templates.put('User', templates.get(Label.ViewingUpdatedUserTemplate));
        return send(events, attendees, templates);
    }

    private Messaging.SendEmailResult[] send(List<Event> events, List<EventRelation> attendees, Map<String,Id> templates) {
        Set<Id> contactsWithEmail = getContactsWithEmail(events, attendees);
        for (EventRelation attendee: attendees) {
            if (isContact(attendee.RelationId) && contactsWithEmail.contains(attendee.RelationId)) {
                messages.add(createMessage(attendee.RelationId, attendee.EventId, templates.get('Contact')));
            } else if (isUser(attendee.RelationId)) {
                messages.add(createMessage(attendee.RelationId, attendee.EventId, templates.get('User')));
            }
        }
        return Messaging.sendEmail(messages);
    }

    private Set<Id> getContactsWithEmail(List<Event> events, List<EventRelation> attendees) {
        Set<Id> contactsIds = new Set<Id>();
        for (EventRelation attendee: attendees) {
            if (isContact(attendee.RelationId)) {
                contactsIds.add(attendee.RelationId);
            }
        }

        return new Map<Id, Contact>([SELECT Id FROM Contact WHERE Id IN : contactsIds AND Email != null LIMIT 10000]).keySet();
    }

    private Messaging.SingleEmailMessage createMessage(Id whoId, Id eventId, Id templateId) {
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTemplateId(templateId);
        message.setToAddresses(new String[] {whoId});
        message.setTargetObjectId(whoId);
        message.setSaveAsActivity(false);
        message.setWhatId(eventId);
        return message;
    }

    private Map<String,Id> getTemplates() {
        List<String> names = new List<String> {Label.ViewingUpdatedContactTemplate, Label.ViewingUpdatedUserTemplate, Label.ViewingCreatedContactTemplate, Label.ViewingCreatedUserTemplate};
        List<EmailTemplate> templates = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN : names LIMIT 100];
        Map<String,Id> result = new Map<String,Id>();
        for (EmailTemplate template: templates) {
            result.put(template.DeveloperName, template.Id);
        }
        return result;
    }

    private boolean isContact(Id id) {
        return !String.isBlank(id) && String.valueof(id).startsWith('003');
    }

    private boolean isUser(Id id) {
        return !String.isBlank(id) && String.valueof(id).startsWith('005');
    }
}