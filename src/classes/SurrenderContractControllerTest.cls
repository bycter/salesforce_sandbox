@IsTest
public with sharing class SurrenderContractControllerTest {
    @IsTest
    public static void testSErvicedSurrender() {
        Account account = RecordDmlTest.createAccount();
        Property__c property = RecordDmlTest.createProperty();
        Pricebook2 priceBook = RecordDmlTest.createPricebook('Serviced');
        Contract contract = new Contract(
            Name = 'TestName',
            AccountId = account.Id,
            Property__c = property.Id,
            Pricebook2Id = priceBook.Id
        );
        insert contract;

        PageReference surrenderPage = Page.SurrenderContract;
        Test.setCurrentPageReference(surrenderPage);
        ApexPages.currentPage().getParameters().put('contractId', contract.Id);
        //then contract found

        //when page opened
        SurrenderContractController controller = new SurrenderContractController(new ApexPages.StandardController(new Contract_Surrender__c()));
        System.assertNotEquals(null, controller.contract);
        controller.surrender.Surrender_Premium__c = 2;
        controller.surrender.Final_Dilapidations__c = 1;
        controller.surrender.Is_the_customer_liable_for_Service_Chrg__c = 'Yes';
        controller.surrender.Is_the_customer_liable_for_electricity__c = 'Yes';
        System.assert(!controller.getSurrenderExists());

        //when surrender
        controller.saveSurrender();

        //then Contract Surrender and Surrender Case created
        System.assertEquals(0, [select count() from Case]);
        System.assertEquals(1, [select count() from Contract_Surrender__c]);
        System.assertNotEquals(null, controller.cancelSurrender());
    }

    @IsTest
    public static void testConventionalSurrender() {
        Account account = RecordDmlTest.createAccount();
        Property__c property = RecordDmlTest.createProperty();
        Pricebook2 priceBook = RecordDmlTest.createPricebook('Conventional');
        Contract contract = new Contract(
            Name = 'TestName',
            AccountId = account.Id,
            Property__c = property.Id,
            Pricebook2Id = priceBook.Id
        );
        insert contract;

        PageReference surrenderPage = Page.SurrenderContract;
        Test.setCurrentPageReference(surrenderPage);
        ApexPages.currentPage().getParameters().put('contractId', contract.Id);
        //then contract found

        //when page opened
        SurrenderContractController controller = new SurrenderContractController(new ApexPages.StandardController(new Contract_Surrender__c()));
        System.assertNotEquals(null, controller.contract);
        controller.surrender.Surrender_Premium__c = 2;
        controller.surrender.Final_Dilapidations__c = 1;
        controller.surrender.Is_the_customer_liable_for_Service_Chrg__c = 'Yes';
        controller.surrender.Is_the_customer_liable_for_electricity__c = 'Yes';

        //when surrender
        controller.saveSurrender();

        //then Contract Surrender and Surrender Case created
        System.assertEquals(1, [select count() from Case]);
        System.assertEquals(1, [select count() from Contract_Surrender__c]);
        System.assertNotEquals(null, controller.cancelSurrender());
    }

    @IsTest
    public static void testErrors() {
        Account account = RecordDmlTest.createAccount();
        Property__c property = RecordDmlTest.createProperty();
        Pricebook2 priceBook = RecordDmlTest.createPricebook('Virtual Sales');
        Contract contract = new Contract(
            Name = 'TestName',
            AccountId = account.Id,
            Property__c = property.Id,
            Pricebook2Id = priceBook.Id
        );
        insert contract;

        PageReference surrenderPage = Page.SurrenderContract;
        Test.setCurrentPageReference(surrenderPage);
        ApexPages.currentPage().getParameters().put('contractId', contract.Id);
        //then contract found

        //when page opened
        SurrenderContractController controller = new SurrenderContractController(new ApexPages.StandardController(new Contract_Surrender__c()));
        System.assertNotEquals(null, controller.contract);
        //then Contract Surrender and Surrender Case created
        System.assert(controller.isMessageRendered);
        Test.setCurrentPageReference(surrenderPage);
        ApexPages.currentPage().getParameters().put('contractId', null);
        controller = new SurrenderContractController(new ApexPages.StandardController(new Contract_Surrender__c()));
        System.assert(controller.isMessageRendered);
    }
}