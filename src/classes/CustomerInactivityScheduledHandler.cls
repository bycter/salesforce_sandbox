public without sharing class CustomerInactivityScheduledHandler implements Schedulable {

    public  static final String INSTANCE_INACTIVITY_EXP_TIME = 'INACTIVITY_EXPIRATION_TIME';
    private static final Integer BATCH_SIZE = 50;
    private static final String QUERY_PATTERN = 'SELECT Id, ' +
            'Closed_Lost_Reason__c, StageName, ' +
            'Closed_Lost_Date__c, ' +
            'LastActivityDate, ' +
            'LastModifiedDate, ' +
            'CloseDate FROM Opportunity ' +
            'WHERE StageName NOT IN (\'Closed Lost\', \'Completed\') ' +
            'AND Days_since_last_customer_activity__c >= ';

    public void execute(SchedulableContext sc) {
        Decimal inactivityExpTime = CustomerInactivitySettings__c.getInstance(
                INSTANCE_INACTIVITY_EXP_TIME).Inactivity_Expiration_Time__c;

        String QUERY = QUERY_PATTERN + String.valueOf(inactivityExpTime);

        CustomerInactivityHandlerBatch batchCustomerInactivityHandler =
                new CustomerInactivityHandlerBatch(QUERY);

        Database.executeBatch(batchCustomerInactivityHandler, BATCH_SIZE);
    }
}