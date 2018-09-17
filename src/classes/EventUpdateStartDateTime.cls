/*
Used for Setting start date time of Event with using User Time Zone
* */
public with sharing class EventUpdateStartDateTime {

    public static void updateDate (List<Event> eventList) {
        for (Event event: eventList) {
            if ( event.StartDateTime != NULL) {
                event.Start_Date_Time__c = (String) event.StartDateTime.format('dd/MM/YYYY HH:mm');
            }
        }

    }

}