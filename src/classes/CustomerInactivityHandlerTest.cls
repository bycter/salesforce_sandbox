@isTest
public class CustomerInactivityHandlerTest {

    @isTest static void SingleActiveOpportunityNoClosingTest() {
        Test.startTest();

        Id recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Agent_Broker' LIMIT 1].Id;

        Account testAccount = new Account(Name = 'Test Account', RecordTypeId = recordTypeId);
        insert testAccount;

        Property__c testProperty = new Property__c(Name = 'Test Property', Street__c = 'Test Address');
        insert testProperty;

        //Given
        Opportunity opportunity = new Opportunity();
        opportunity.Name = 'Customer inactivity test ' + String.valueOf(System.today());
        opportunity.StageName = 'Qualified';
        opportunity.Type = 'New Customer';
        opportunity.CloseDate = Date.valueOf('2019-01-01');
        opportunity.Region__c = 'Leeds';
        opportunity.LeadSource = 'Agent';
        opportunity.Channel__c = 'Email';
        opportunity.Agent_Broker__c = testAccount.Id;
        insert opportunity;

        CustomerInactivitySettings__c settings = new CustomerInactivitySettings__c();
        settings.Name = 'INACTIVITY_EXPIRATION_TIME';
        settings.Inactivity_Expiration_Time__c = 180;
        insert settings;

        //When
        String jobId = System.schedule('testBasicScheduleApex', '0 0 0 * * ?',
            new CustomerInactivityScheduledHandler());

        CronTrigger cronTrigger = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                                   FROM CronTrigger WHERE Id = :jobId];
        Time expectTime = Time.newInstance(0, 0, 0, 0);
        Datetime expectNextFireTime = Datetime.newInstance(System.now().date() + 1, expectTime);

        System.assertEquals(cronTrigger.CronExpression, '0 0 0 * * ?');
        System.assertEquals(0, cronTrigger.TimesTriggered);
        System.assertEquals(expectNextFireTime, cronTrigger.NextFireTime);

        Test.stopTest();

        Opportunity retrievedOpportunity = [SELECT Id, StageName, IsClosed, Name, CloseDate, Closed_Lost_Date__c, Closed_Lost_Reason__c
                       FROM Opportunity WHERE Id = :opportunity.Id];
        //Then
        System.assertEquals(opportunity.Id, retrievedOpportunity.Id);
        System.assertEquals(Opportunity.Name, retrievedOpportunity.Name);
        System.assertNotEquals(System.now().date(), retrievedOpportunity.CloseDate);
        System.assertNotEquals(System.now().date(), retrievedOpportunity.Closed_Lost_Date__c);
        System.assertNotEquals('Inactivity', retrievedOpportunity.Closed_Lost_Reason__c);
        System.assertNotEquals('Closed Lost', retrievedOpportunity.StageName);
        System.assertNotEquals(true, retrievedOpportunity.IsClosed);
    }
}