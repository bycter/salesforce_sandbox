@isTest
public class PostDeploySetupTest {
    @isTest
    static void whenPostDeployThenConfigCreated() {
        //when
        PostDeploySetup.setup();

        //then
        System.assertEquals(1, [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :PostDeploySetup.CUSTOMER_INACTIVITY_SCHEDULED_JOB_NAME].size());
        System.assertEquals(1, [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :PostDeploySetup.VIEWING_FEEDBACK_SCHEDULED_JOB_NAME].size());
        System.assertNotEquals(null, CustomerInactivitySettings__c.getInstance(CustomerInactivityScheduledHandler.INSTANCE_INACTIVITY_EXP_TIME));
        //System.assertEquals(1, [select id from CaseTeamRole where Name = :'Default'].size());
    }

    @isTest
    static void whenPostDeployCaseTeamThenTeamCreated() {
        //when
        PostDeploySetup.setupCaseTeam();

        //then
        System.assertEquals(1, [select id from CaseTeamTemplate where Name = :CaseTriggerHandler.LEASE_TRANSACTION_CASE_TEAM].size());
    }

    @isTest
    static void givenPriceBookswhenAssignTRToPBThenAssigned() {
        RecordDmlTest.createPricebook('Conventional Sales');
        RecordDmlTest.createPricebook('Serviced Sales');
        RecordDmlTest.createPricebook('Virtual Sales');

        //when
        PostDeploySetup.assignRTToPriceBooks();

        //then
        List<Pricebook2> pricebooks = [select Id, Name, RecordTypeId from Pricebook2 where isStandard = false];
        for (Pricebook2 pricebook : pricebooks) {
            System.assertNotEquals(null, pricebook.RecordTypeId);
            System.assert(pricebook.Name.contains(Schema.SObjectType.Pricebook2.getRecordTypeInfosById().get(pricebook.RecordTypeId).Name));
        }
    }

    @isTest
    static void whenCleanConfigurationAttributesFieldsThenFieldsEmpty() {
        Product2 product2 = RecordDmlTest.createProducts().get(0);
        SBQQ__ConfigurationAttribute__c ca = new SBQQ__ConfigurationAttribute__c(
                SBQQ__PRODUCT__C = product2.Id, 
                SBQQ__DEFAULTOBJECT__C = 'Quote__c', 
                SBQQ__DEFAULTFIELD__C = 'Headline_Item_Subscription_Term__c',
                SBQQ__COLUMNORDER__C='1',
                SBQQ__TargetField__c='Term__c',
                SBQQ__ApplyToProductOptions__c=false);

        insert ca;
        //when
        PostDeploySetup.cleanConfigurationAttributesFields();

        //then
        System.assertEquals(0, [select id from SBQQ__ConfigurationAttribute__c where SBQQ__DEFAULTOBJECT__C != null or SBQQ__DEFAULTFIELD__C != null].size());
    }
}