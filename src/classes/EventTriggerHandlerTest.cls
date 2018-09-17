/**
 * Created by v2.nareyko on 29.04.18.
 */

@IsTest
private class EventTriggerHandlerTest {

    @isTest
    static void givenPropertyWhenViewingCreatedThenEventRelationsCreated() {
        // given
        Property__c property = RecordDmlTest.createProperty();
        User propertyManager = RecordDmlTest.createUser();
        User receptionUser = RecordDmlTest.createUser();
        property.Reception__c = receptionUser.Id;
        property.Property_Manager__c = propertyManager.Id;
        update property;
        Product2 product = new Product2(Name = 'Car Parking License', Productcode = 'CarParkLicense', Family = 'Car space', HOT_TYPE__C = 'CarParkLicense', IsActive = true);
        insert product;
        Opportunity opportunity = RecordDmlTest.createOpportunity(OpportunityService.CONVENTIONAL_RECORD_TYPE);

        // when
        RecordDmlTest.createViewingEvent(RecordDmlTest.createContact().Id, opportunity.Id, property.Id);

        // then
        System.assertEquals(1, [SELECT Id FROM EventRelation WHERE RelationId = :propertyManager.Id].size());
        System.assertEquals(1, [SELECT Id FROM EventRelation WHERE RelationId = :receptionUser.Id].size());
    }
}