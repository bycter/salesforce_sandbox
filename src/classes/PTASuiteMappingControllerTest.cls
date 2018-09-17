@isTest
public with sharing class PTASuiteMappingControllerTest {
    @isTest
    static void testControllerLifecycle() {
        //given
        Property__c property1 = RecordDmlTest.createProperty();
        RecordDmlTest.createProducts();
        Product2 suiteProduct = [select id from Product2 where Family = 'suite' and ProductCode='OfficeRent' limit 1];

        Inventory__c actualInventory1 = RecordDmlTest.createActualSuiteInventory(suiteProduct, property1);
        actualInventory1.Sales_Status__c = 'Not Available';
        update actualInventory1;
        Inventory__c actualInventory2 = RecordDmlTest.createActualSuiteInventory(suiteProduct, property1);
        Inventory__c actualInventory3 = RecordDmlTest.createActualSuiteInventory(suiteProduct, property1);

        Inventory__c proposedInventory = RecordDmlTest.createProposedSuiteInventory(suiteProduct, property1);

        PageReference mappingPage = Page.ProposedToActualSuiteMapping;
        Test.setCurrentPageReference(mappingPage);
        ApexPages.currentPage().getParameters().put('proposedSuiteId', proposedInventory.Id);
        
        //when page opened
        ProposedToActualSuiteMappingController controller = new ProposedToActualSuiteMappingController();
        
        //then all Actual available inventories from the Property appears in the ActualSuites 
        System.assertEquals(2, controller.getActualSuites().size());
        System.assertEquals(0, controller.selectedSuitesIds.size());

        //when we save with selected suites
        controller.selectedSuitesIds.add(actualInventory2.Id);
        PageReference saveReference = controller.save();
        //then Mapping created
        System.assertEquals(1, [select count() from Proposed_to_Actual_Suite_Mapping__c]);
        //then user routed to proposed suite page
        System.assertEquals('/' + proposedInventory.Id, saveReference.getUrl());

        //when we reload page
        controller = new ProposedToActualSuiteMappingController();
        //then available suites the same, one selected
        System.assertEquals(2, controller.getActualSuites().size());
        System.assertEquals(1, controller.selectedSuitesIds.size());
        
        //when we saving mapping again
        controller.save();
        //then no duplicates created:
        System.assertEquals(1, [select count() from Proposed_to_Actual_Suite_Mapping__c]);
        
        //when we clear proposed suite
        controller.searchMapping.Proposed_Suite__c = null;
        //then no available suites shown
        System.assertEquals(0, controller.getActualSuites().size());

        //when rerender without selected proposed suite
        controller.rerenderActualSuites();
        //then still no available suites shown
        System.assertEquals(0, controller.getActualSuites().size());
        
        //when we try to save without proposed suite 
        saveReference = controller.save();
        //then error shown and reference is null
        System.assertEquals(ApexPages.Severity.ERROR, ApexPages.getMessages().get(0).getSeverity());
        System.assertEquals(null, saveReference);
        
        //when click on cancel
        controller = new ProposedToActualSuiteMappingController();
        PageReference cancelReference = controller.cancel();
        //then route to proposed suite page
        System.assertEquals('/' + proposedInventory.Id, cancelReference.getUrl());
    }
}