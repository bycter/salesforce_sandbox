@isTest
public with sharing class CodaCompanyTriggerHandlerTest {
    @isTest
    public static void whenCompanyCreatedRTSetFromField() {
        c2g__codaCompany__c company1 = new c2g__codaCompany__c();
        company1.RecordTypeDeveloperName__c = 'SUT';

        c2g__codaCompany__c company2 = new c2g__codaCompany__c();
        company2.RecordTypeDeveloperName__c = 'VAT';

        insert new List<c2g__codaCompany__c>{
                company1, company2
        };

        for (c2g__codaCompany__c company : [select RecordType.DeveloperName, RecordTypeDeveloperName__c from c2g__codaCompany__c c]) {
            System.assertEquals(company.RecordType.DeveloperName, company.RecordTypeDeveloperName__c);
        }
    }
}