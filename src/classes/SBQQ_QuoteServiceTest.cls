@IsTest
public class SBQQ_QuoteServiceTest {
    @IsTest
    static void testCallExpiryFullTermFieldFieldONQuoteFalseValue() {
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);

        Test.startTest();
            quote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
            update quote;
        Test.stopTest();

        SBQQ__Quote__c testQuote = [SELECT Id, CapExpiryFullTerm__c FROM SBQQ__Quote__c WHERE Id=: quote.Id LIMIT 1];
        System.assert(!testQuote.CapExpiryFullTerm__c, 'The CapExpiryFullTerm__c is TRUE only when Quote has ServiceCharge and ServiceChargeCap products');
        System.assertNotEquals(null, ProductService.PRODUCT_CODE_SERVICE_CHARGE);
        System.assertNotEquals(null, ProductService.PRODUCT_CODE_SERVICE_CHARGE_CAP);
    }

    @IsTest
    static void testCallExpiryFullTermFieldFieldONQuoteTrueValue() {
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithServiceChargeCapLines();

        Test.startTest();
            quote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
            update quote;
        Test.stopTest();

        SBQQ__Quote__c testQuote = [SELECT Id, CapExpiryFullTerm__c FROM SBQQ__Quote__c WHERE Id=: quote.Id LIMIT 1];
        System.assert(testQuote.CapExpiryFullTerm__c, 'The CapExpiryFullTerm__c is TRUE only when Quote has ServiceCharge and ServiceChargeCap products');
    }

    @IsTest
    static void testConcessionLogic() {
        SBQQ.TriggerControl.disable();
        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithServiceChargeCapLines();

        Test.startTest();
            quote.SBQQ__Status__c = SBQQ_QuoteConstants.STATUS_ACCEPTED;
            update quote;
        Test.stopTest();

        System.assert([SELECT COUNT() FROM SBQQ__QuoteLine__c WHERE IsConcession__c = TRUE] > 0, 'Concession products in QLI');
        System.assert([SELECT COUNT() FROM SBQQ__Subscription__c WHERE IsConcession__c = TRUE] > 0, 'Concession products in QLI');
    }

    @IsTest
    static void testParkingInfo() {
        //given
        SBQQ__Quote__c quote = RecordDmlTest.preGenerateQuote('Serviced');
        User propertyManager = RecordDmlTest.createUser();

        Property__c property = [SELECT Id, Property_Manager__c FROM Property__c WHERE Id = :quote.Property__c];
        property.Serviced_Space_Coordinator__c = propertyManager.Id;
        upsert property;
        //TODO:extract and eliminate code duplication
        List<Product2> products = new List<Product2>();
        Product2 officeRentProduct = new Product2(Name = 'Office Rent', Family = 'Suite', ProductCode='Storage');
        products.add(officeRentProduct);
        Product2 carParkingLicenseProduct = new Product2(Name = 'Car Parking License', Family = 'Parking', ProductCode='CarParkLicense');
        products.add(carParkingLicenseProduct);
        Product2 carSpaceProduct = new Product2(Name = 'Car Space', Family = 'Parking', ProductCode='CarSpace');
        products.add(carSpaceProduct);
        Product2 halfRent = new Product2(Name = 'Half Rent', ProductCode = 'HalfRent', Family = 'Days', IsConcession__c = true);
        products.add(halfRent);
        insert products;

        Inventory__c officeRentInventory = RecordDmlTest.createActualSuiteInventory(officeRentProduct, property);
        Inventory__c carParkingInventory = RecordDmlTest.createActualCarParkingInventory(carSpaceProduct, property);

        SBQQ__QuoteLine__c suite = RecordDmlTest.generateLine(officeRentProduct, quote.Id, officeRentInventory.Id, null);
        suite.Quanta__c = 'suite';
        suite.Net_Total__c = 100;
        suite.Term__c = 10;
        SBQQ.TriggerControl.disable();
        insert suite;

        SBQQ__QuoteLine__c parking = RecordDmlTest.generateLine(carSpaceProduct, quote.Id, carParkingInventory.Id, null);
        parking.Car_Parking_Inventory__c = carParkingInventory.Id;
        parking.Net_Total__c = 100;
        parking.Term__c = 10;
 
        SBQQ__QuoteLine__c halfRentLine = RecordDmlTest.generateLine(halfRent, quote.Id, officeRentInventory.Id, suite.Id);

        Test.startTest();
        SBQQ.TriggerControl.disable();
        insert new List<SBQQ__QuoteLine__c>{
            parking, halfRentLine
        };
        Test.stopTest();

        quote = [SELECT Id, Total_Parking_Spaces__c, Total_Annualised_Cost_of_Parking_Spaces__c FROM SBQQ__Quote__c WHERE Id =: quote.Id];
        halfRentLine = [SELECT Id, Half_Rent_Annualised_Amount__c, Half_Rent_Annualised_text__c FROM SBQQ__QuoteLine__c WHERE Id =: halfRentLine.Id];
        System.assertEquals(1, quote.Total_Parking_Spaces__c);
        System.assertEquals( ((parking.Net_Total__c / parking.Term__c) * 12) , quote.Total_Annualised_Cost_of_Parking_Spaces__c);
        System.assertEquals( ( ((suite.Net_Total__c / suite.Term__c) * 12 ) / 2 ), halfRentLine.Half_Rent_Annualised_Amount__c);
        System.assertNotEquals(null, halfRentLine.Half_Rent_Annualised_text__c);
    }
}