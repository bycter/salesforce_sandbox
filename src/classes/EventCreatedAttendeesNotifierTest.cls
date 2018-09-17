@isTest
public class EventCreatedAttendeesNotifierTest {

    @isTest
    public static void notifyTest() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            RecordDmlTest.createEmailTemplates();
            EventCreatedAttendeesNotifier.notify(new List<Id> { RecordDmlTest.createEvent().Id });
        }
    }

}