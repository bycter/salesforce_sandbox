@isTest
public with sharing class InventoryTriggerHandlerTest {
    @isTest
    public static void whenInventoryCreatedRTSetFromField() {
        Property__c testProperty = RecordDmlTest.createProperty();

        Product2 product = new Product2(Name = 'Test Product', IsActive = true, Family = 'Suite', ProductCode = 'OfficeRent');
        Database.insert(product);

        Inventory__c inventory1 = RecordDmlTest.createInventoryNoInsert(product, testProperty, null, 'Actual');
        inventory1.RecordTypeDeveloperName__c = 'Actual_Suite';

        Inventory__c inventory2 = RecordDmlTest.createInventoryNoInsert(product, testProperty, null, 'Proposed');
        inventory2.RecordTypeDeveloperName__c = 'Proposed_Suite';

        insert new List<Inventory__c>{
                inventory1, inventory2
        };

        for (Inventory__c inventory : [select RecordType.DeveloperName, RecordTypeDeveloperName__c from Inventory__c]) {
            System.assertEquals(inventory.RecordType.DeveloperName, inventory.RecordTypeDeveloperName__c);
        }
    }
}