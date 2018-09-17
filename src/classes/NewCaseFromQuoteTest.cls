@IsTest
private class NewCaseFromQuoteTest {

    @IsTest
    static void givenSerQuoteWhenQuoteAcceptedThenCasesCreated() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.preGenerateQuote('Serviced');

        Opportunity opportunity = [SELECT AccountId FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c];
        opportunity.Briefing_Statement__c = 'test statement';
        upsert opportunity;

        Contact contact = new Contact(AccountId = opportunity.AccountId, Contact_Type__c = 'In Life Property Contact', LastName = 'Test Contact');
        insert contact;

        User propertyManager = RecordDmlTest.createUser();

        Property__c property = [SELECT Id, Property_Manager__c FROM Property__c WHERE Id = :quote.Property__c];
        property.Serviced_Space_Coordinator__c = propertyManager.Id;
        upsert property;

        //TODO:extract and eliminate code duplication
        List<Product2> products = new List<Product2>();
        Product2 storageProduct = new Product2(Name = 'Storage', Family = 'Suite', ProductCode='Storage');
        products.add(storageProduct);
        Product2 officeRentProduct = new Product2(Name = 'Office Rent', Family = 'Suite', ProductCode='OfficeRent');
        products.add(officeRentProduct);
        Product2 carSpaceProduct = new Product2(Name = 'Car Space', Family = 'Parking', ProductCode='CarSpace');
        products.add(carSpaceProduct);
        Product2 carParkingLicenseProduct = new Product2(Name = 'Car Parking License', Family = 'Parking', ProductCode='CarParkLicense');
        products.add(carParkingLicenseProduct);
        Product2 handset = new Product2(Name = 'Handsets', ProductCode = 'BSHD', Family = '');
        products.add(handset);
        insert products;

        Inventory__c storageInventory = RecordDmlTest.createActualSuiteInventory(storageProduct, property);
        Inventory__c officeRentInventory = RecordDmlTest.createActualSuiteInventory(officeRentProduct, property);
        Inventory__c carParkingInventory = RecordDmlTest.createActualCarParkingInventory(carSpaceProduct, property);
        Inventory__c handSetInventory = RecordDmlTest.createActualCarParkingInventory(handset, property);

        SBQQ__QuoteLine__c suite = RecordDmlTest.generateLine(officeRentProduct, quote.Id, officeRentInventory.Id, null);
        SBQQ.TriggerControl.disable();
        insert suite;

        SBQQ__QuoteLine__c storage = RecordDmlTest.generateLine(storageProduct, quote.Id, storageInventory.Id, null);
        storage.Comparable_ID_for_Calculator__c = 'STR-1';
        storage.Bundle_Code__c = ProductService.PRODUCT_CODE_STORAGE;

        SBQQ__QuoteLine__c parking = RecordDmlTest.generateLine(carSpaceProduct, quote.Id, carParkingInventory.Id, null);
        parking.Car_Parking_Inventory__c = carParkingInventory.Id;

        SBQQ__QuoteLine__c handsetLine = RecordDmlTest.generateLine(handset, quote.Id, handSetInventory.Id, suite.Id);
        handsetLine.SBQQ__Quantity__c = 3;

        SBQQ.TriggerControl.disable();
        insert new List<SBQQ__QuoteLine__c>{
                storage, parking, handsetLine
        };

        Test.startTest();
        SBQQ_QuoteService.cleanup();
        ContactService.cleanup();
        //when
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        //then
        Case parentCase = [
                SELECT Id, OwnerId, AccountId, ContactId, Briefing_Statement__c, BusinessHoursId, CurrencyIsoCode,
                        Sales_Contact__c, Property__c, Quote__c, RecordTypeId, Status,
                        Storage_1_Inventory__c, Inventory__c, Commencement_Date__c, Car_Parkings__c, Opportunity__c, Number_of_Phones__c
                FROM Case
                WHERE OwnerId = :propertyManager.Id AND
                RecordTypeId = :RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.SERVICED_SPACE_ONBOARDING_RECORD_TYPE)
        ];

        System.assertEquals(propertyManager.Id, parentCase.OwnerId);
        System.assertEquals(CaseService.getDefaultBusinessHours().Id, parentCase.BusinessHoursId);
        System.assertEquals(opportunity.Briefing_Statement__c, parentCase.Briefing_Statement__c);
        System.assertEquals('GBP', parentCase.CurrencyIsoCode);
        System.assertEquals(contact.Id, parentCase.ContactId);
        System.assertEquals(quote.SBQQ__PrimaryContact__c, parentCase.Sales_Contact__c);
        System.assertEquals(quote.Property__c, parentCase.Property__c);
        System.assertEquals(quote.Id, parentCase.Quote__c);
        System.assertEquals(RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.SERVICED_SPACE_ONBOARDING_RECORD_TYPE), parentCase.RecordTypeId);
        System.assertEquals('New', parentCase.Status);
        System.assertEquals(officeRentInventory.Id, parentCase.Inventory__c);
        System.assertNotEquals(null, parentCase.Commencement_Date__c);
        System.assertEquals(opportunity.AccountId, parentCase.AccountId);
        System.assertEquals(opportunity.Id, parentCase.Opportunity__c);
        System.assertEquals(handsetLine.SBQQ__Quantity__c, parentCase.Number_of_Phones__c);
        System.assert(String.isNotBlank(parentCase.Car_Parkings__c));
    }

    @IsTest
    static void givenConQuoteWhenQuoteAcceptedThenCasesCreated() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.preGenerateQuote('Conventional');

        Opportunity opportunity = [SELECT AccountId FROM Opportunity WHERE Id = :quote.SBQQ__Opportunity2__c];
        opportunity.Briefing_Statement__c = 'test statement';
        update opportunity;

        Contact contact = new Contact(AccountId = opportunity.AccountId, Contact_Type__c = 'In Life Property Contact', LastName = 'Test Contact');
        insert contact;

        User propertyManager = RecordDmlTest.createUser();

        Property__c property = [SELECT Id, Property_Manager__c FROM Property__c WHERE Id = :quote.Property__c];
        property.Property_Manager__c = propertyManager.Id;
        upsert property;

        List<Product2> products = new List<Product2>();
        Product2 storageProduct = new Product2(Name = 'Storage', Family = 'Suite', ProductCode='Storage' );
        products.add(storageProduct);
        Product2 officeRentProduct = new Product2(Name = 'Office Rent', Family = 'Suite', ProductCode='OfficeRent');
        products.add(officeRentProduct);
        Product2 carParkingLicenseProduct = new Product2(Name = 'Car Parking License', Family = 'Parking', ProductCode='CarParkLicense');
        products.add(carParkingLicenseProduct);
        Product2 carSpaceProduct = new Product2(Name = 'Car Space', Family = 'Parking', ProductCode='CarSpace');
        products.add(carSpaceProduct);
        insert products;

        Inventory__c storageInventory = RecordDmlTest.createActualSuiteInventory(storageProduct, property);
        Inventory__c officeRentInventory = RecordDmlTest.createActualSuiteInventory(officeRentProduct, property);
        Inventory__c carParkingInventory = RecordDmlTest.createActualCarParkingInventory(carSpaceProduct, property);

        SBQQ__QuoteLine__c suite = RecordDmlTest.generateLine(officeRentProduct, quote.Id, officeRentInventory.Id, null);
        suite.Quanta__c = 'suite';

        SBQQ__QuoteLine__c storage = RecordDmlTest.generateLine(storageProduct, quote.Id, storageInventory.Id, null);
        storage.Comparable_ID_for_Calculator__c = 'STR-1';
        storage.Bundle_Code__c = ProductService.PRODUCT_CODE_STORAGE;

        SBQQ__QuoteLine__c parking = RecordDmlTest.generateLine(carSpaceProduct, quote.Id, carParkingInventory.Id, null);
        parking.Car_Parking_Inventory__c = carParkingInventory.Id;

        SBQQ.TriggerControl.disable();
        insert new List<SBQQ__QuoteLine__c>{
                suite, storage, parking
        };

        Test.startTest();
        SBQQ_QuoteService.cleanup();
        ContactService.cleanup();
        //when
        quote.SBQQ__Status__c = 'Accepted';
        update quote;
        Test.stopTest();

        //then
        Case parentCase = [
                SELECT Id, OwnerId, AccountId, ContactId, Briefing_Statement__c, BusinessHoursId, CurrencyIsoCode,
                        Sales_Contact__c, Property__c, Quote__c, RecordTypeId, Status,
                        Storage_1_Inventory__c, Inventory__c, Commencement_Date__c, Car_Parkings__c, Opportunity__c
                FROM Case
                WHERE OwnerId = :propertyManager.Id AND ParentId != null AND
                RecordTypeId = :RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.CONVENTIONAL_ONBOARDING_RECORD_TYPE)
        ];

        System.assertEquals(propertyManager.Id, parentCase.OwnerId);
        System.assertEquals(CaseService.getDefaultBusinessHours().Id, parentCase.BusinessHoursId);
        System.assertEquals(opportunity.Briefing_Statement__c, parentCase.Briefing_Statement__c);
        System.assertEquals('GBP', parentCase.CurrencyIsoCode);
        System.assertEquals(contact.Id, parentCase.ContactId);
        System.assertEquals(quote.SBQQ__PrimaryContact__c, parentCase.Sales_contact__c);
        System.assertEquals(quote.Property__c, parentCase.Property__c);
        System.assertEquals(quote.Id, parentCase.Quote__c);
        System.assertEquals(RecordTypeHelper.getCaseRtIdByDeveloperName(CaseService.CONVENTIONAL_ONBOARDING_RECORD_TYPE), parentCase.RecordTypeId);
        System.assertEquals('New', parentCase.Status);
        System.assertEquals(storageInventory.Id, parentCase.Storage_1_Inventory__c);
        System.assertEquals(officeRentInventory.Id, parentCase.Inventory__c);
        System.assertNotEquals(null, parentCase.Commencement_Date__c);
        System.assertEquals(opportunity.AccountId, parentCase.AccountId);
        System.assertEquals(opportunity.Id, parentCase.Opportunity__c);
        System.assert(String.isNotBlank(parentCase.Car_Parkings__c));
    }

}