public without sharing class QueueHelper {

    public class QueueException extends Exception {
    }

    public static final String LEASE_TRANSACTION_QUEUE = 'Lease_Transaction';
    public static final String B_C_QUEUE = 'B_C_Queue';

    private static Map<String, Id> developerNameToRecordId = new Map<String, Id>();

    static {
        for (Group queue : [
                SELECT Id, DeveloperName
                FROM Group
                WHERE Type = 'Queue'
        ]) {
            developerNameToRecordId.put(queue.DeveloperName, queue.Id);
        }
    }

    public static Id getRtIdByDeveloperName(String developerName) {
        if (!developerNameToRecordId.containsKey(developerName)) {
            throw new QueueException('Queue with DeveloperName: "' + developerName + '" does not exist.');
        }
        return developerNameToRecordId.get(developerName);
    }
}