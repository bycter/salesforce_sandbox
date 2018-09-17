trigger CodaCompanyTrigger on c2g__codaCompany__c (before insert) {
    new CodaCompanyTriggerHandler().run();
}