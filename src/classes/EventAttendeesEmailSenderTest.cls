@isTest
public class EventAttendeesEmailSenderTest {

    public static EventAttendeesEmailSender sender = new EventAttendeesEmailSender();


    @isTest
    public static void sendOnCreateTest(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            RecordDmlTest.createEmailTemplates();
            validateResults(sender.sendOnCreate(RecordDmlTest.createEvents(), RecordDmlTest.createEventRelations()));
        }
    }

    @isTest
    public static void sendOnUpdateTest(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(u) {
            RecordDmlTest.createEmailTemplates();
            validateResults(sender.sendOnUpdate(RecordDmlTest.createEvents(), RecordDmlTest.createEventRelations()));
        }
    }


    private static void validateResults(Messaging.SendEmailResult[] results) {
        for (Messaging.SendEmailResult result : results) {
                System.assert(result.success, 'An error on an email sending');
        }
    }
}