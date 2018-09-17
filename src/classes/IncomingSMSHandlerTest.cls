@isTest
public class IncomingSMSHandlerTest {
    public IncomingSMSHandlerTest() {
        
    }
    @testSetup
    public static void initData(){
        
        Account testAccount = new Account(
            Name = 'Bruntwood');
        Database.insert(testAccount);

        Contact testContact = new Contact(
                FirstName = 'John',
                LastName = 'Brown',
                Email = 'test545343@test5663.com',
                MobilePhone = '07960744016',
                AccountId = testAccount.Id);
        Database.insert(testContact);

        Property__c testProperty = RecordDmlTest.createProperty();
        testProperty.Name = 'Hatch';
        update testProperty;


        Opportunity o = new Opportunity(AccountId = null, Name = 'opportunityName',
        StageName='Prospecting', CloseDate=Date.today(), Channel__c = 'Email');
        Database.insert(o);
        
        Product2 p2 = new Product2(Name='Test Product',isActive=true);
        Database.insert(p2);


        Id recordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Viewing').getRecordTypeId();
        Event testEvent = new Event(
            RecordTypeId = recordTypeId,
            Property__c = testProperty.Id,
            Status__c = 'Booked',
            Viewing_Arranged_by__c = 'Sales',
            Viewing_Conducted_by__c = 'Sales',
            OwnerId = UserInfo.getUserId(),
            WhoId = testContact.Id,
            WhatId = RecordDmlTest.createOpportunity('Conventional').Id,
            Viewing_Conducted_by_User__c = RecordDmlTest.createUser().Id,
            StartDateTime = Date.today().addDays(1),
            EndDateTime = Date.today().addDays(2));
        Database.insert(testEvent);
    }

    @isTest
    public static void testSMSHandlerYes(){

        List<smagicinteract__Incoming_SMS__c> smsList = new List<smagicinteract__Incoming_SMS__c>();        
        Contact testContact = [
            SELECT Name, MobilePhone, AccountId
            FROM Contact 
            LIMIT 1];

        Test.startTest();
        smagicinteract__Incoming_SMS__c testIncSMS = new smagicinteract__Incoming_SMS__c(
            smagicinteract__external_field__c = 'I-00000001',
            smagicinteract__Inbound_Number__c = '447960744016',
            smagicinteract__Mobile_Number__c = '447960744016',
            smagicinteract__SMS_Text__c = 'Yes',
            smagicinteract__Contact__c = testContact.Id);
        Database.insert(testIncSMS);
        testIncSMS = [SELECT Id, smagicinteract__Contact__c, smagicinteract__external_field__c, Mobile_Number_Formatted__c, smagicinteract__Inbound_Number__c, smagicinteract__Mobile_Number__c, smagicinteract__SMS_Text__c FROM smagicinteract__Incoming_SMS__c WHERE Id = :testIncSMS.Id];
        smsList.add(testIncSMS);
        IncomingSMSHandler.getConfirmationAction(smsList);
        Test.stopTest();

        Event testEvent = [SELECT Status__c, Status_Updated_By_Customer__c FROM Event LIMIT 1];
        System.assertEquals(Label.Viewing_SMS_Yes, testEvent.Status__c, 'Event status should be confirmed after receiving incoming sms with a YES answer');
        System.assertEquals(true, testEvent.Status_Updated_By_Customer__c, 'Event should be marked as updated with confirmation Yes');
    }

    @isTest
    public static void testSMSHandlerNo(){

        List<smagicinteract__Incoming_SMS__c> smsList = new List<smagicinteract__Incoming_SMS__c>();
        Contact testContact = [
            SELECT Name, MobilePhone, AccountId
            FROM Contact 
            LIMIT 1];

        Test.startTest();
        smagicinteract__Incoming_SMS__c testIncSMS = new smagicinteract__Incoming_SMS__c(
            smagicinteract__external_field__c = 'I-00000001',
            smagicinteract__Inbound_Number__c = '447960744016',
            smagicinteract__Mobile_Number__c = '447960744016',
            smagicinteract__SMS_Text__c = 'No',
            smagicinteract__Contact__c = testContact.Id);
        Database.insert(testIncSMS);
        testIncSMS = [SELECT Id, smagicinteract__Contact__c, smagicinteract__external_field__c, Mobile_Number_Formatted__c, smagicinteract__Inbound_Number__c, smagicinteract__Mobile_Number__c, smagicinteract__SMS_Text__c FROM smagicinteract__Incoming_SMS__c WHERE Id = :testIncSMS.Id];
        smsList.add(testIncSMS);
        IncomingSMSHandler.getConfirmationAction(smsList);
        Test.stopTest();

        Event testEvent = [SELECT Status__c, Status_Updated_By_Customer__c FROM Event LIMIT 1];
        System.assertEquals(Label.Viewing_SMS_No, testEvent.Status__c, 'Event status should be cancelled after receiving incoming sms with a NO answer');
        System.assertEquals(true, testEvent.Status_Updated_By_Customer__c, 'Event should be marked as updated with confirmation No');
    }

    @isTest
    public static void testSMSHandlerContact(){

        List<smagicinteract__Incoming_SMS__c> smsList = new List<smagicinteract__Incoming_SMS__c>();
        Contact testContact = [
            SELECT Name, MobilePhone, AccountId
            FROM Contact 
            LIMIT 1];
        Event testEvent = [SELECT WhoId FROM Event LIMIT 1];
        testEvent.WhoId = testContact.Id;
        Database.update(testEvent);

        Test.startTest();
        smagicinteract__Incoming_SMS__c testIncSMS = new smagicinteract__Incoming_SMS__c(
            smagicinteract__external_field__c = 'I-00000001',
            smagicinteract__Inbound_Number__c = '447960744016',
            smagicinteract__Mobile_Number__c = '447960744016',
            smagicinteract__SMS_Text__c = 'No',
            smagicinteract__Contact__c = testContact.Id);
        Database.insert(testIncSMS);
        testIncSMS = [SELECT Id, smagicinteract__Contact__c, smagicinteract__external_field__c, Mobile_Number_Formatted__c, smagicinteract__Inbound_Number__c, smagicinteract__Mobile_Number__c, smagicinteract__SMS_Text__c FROM smagicinteract__Incoming_SMS__c WHERE Id = :testIncSMS.Id];
        smsList.add(testIncSMS);
        IncomingSMSHandler.getConfirmationAction(smsList);        
        Test.stopTest();

        testEvent = [SELECT Status__c, Status_Updated_By_Customer__c FROM Event LIMIT 1];
        System.assertEquals(Label.Viewing_SMS_No, testEvent.Status__c, 'Event status should be cancelled after receiving incoming sms with a NO answer');
        System.assertEquals(true, testEvent.Status_Updated_By_Customer__c, 'Event should be marked as updated with confirmation');
    }
}