@isTest
private class CreateAdHocRecordsControllerTest {

    @testSetup
    public static void createTestData() {
        Test.startTest();

        RecordDmlTest.createProducts();
        Product2 suiteProduct = [SELECT Id FROM Product2 WHERE Family = 'suite' AND ProductCode = 'OfficeRent' LIMIT 1];

        c2g__codaTaxCode__c taxCode = RecordDmlTest.createTaxCode(CreateAdHocRecordsController.TAX_CODE_NAME);
        c2g__codaCompany__c company = RecordDmlTest.createCompany(CreateAdHocRecordsController.COMPANY_NAME);
        Property__c prop = RecordDmlTest.createProperty();

        Account testAccount = RecordDmlTest.createAccount();

        List<Ad_hoc_Revenue__c> revenues = RecordDmlTest.createAdHocRevenues(testAccount, taxCode, prop, company, suiteProduct);
        insert revenues;

        List<Meeting_Room_Booking__c> rooms = new List<Meeting_Room_Booking__c>();
        for (Integer i = 1; i <= 6; i++) {
            rooms.add(
                    generateMeetingRoom(testAccount, i)
            );
        }
        rooms.get(2).Ad_hoc_Revenue__c = revenues.get(0).Id;
        rooms.get(4).Ad_hoc_Revenue__c = revenues.get(0).Id;
        insert rooms;
        Test.stopTest();
    }

    @isTest static void testBulkCreation() {
        List<Meeting_Room_Booking__c> rooms = [SELECT Id FROM Meeting_Room_Booking__c];
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(rooms);
        stdSetController.setSelected(rooms);

        Test.startTest();
        CreateAdHocRecordsController controller = new CreateAdHocRecordsController(stdSetController);
        PageReference thePage = controller.createRecords();
        System.assert(thePage == null);
        System.assert(rooms.size() == [SELECT COUNT() FROM Ad_hoc_Revenue__c]);
        System.assert(rooms.size() == controller.adHocRecords.size());
        Test.stopTest();
    }

    @isTest static void testSingleRecordCreation() {
        Meeting_Room_Booking__c room = [SELECT Id FROM Meeting_Room_Booking__c WHERE Ad_hoc_Revenue__c = null LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(room);

        Test.startTest();
        CreateAdHocRecordsController controller = new CreateAdHocRecordsController(stdController);
        PageReference thePage = controller.createRecords();
        System.assert(thePage != null);
        System.assert(3 == [SELECT COUNT() FROM Ad_hoc_Revenue__c]);
        System.assert(1 == controller.adHocRecords.size());
        System.assert(String.isBlank(controller.adHocRecords.get(0).message));
        Test.stopTest();
    }

    private static Meeting_Room_Booking__c generateMeetingRoom(Account testAccount, Integer i) {
        return new Meeting_Room_Booking__c(
                Code__c = String.valueOf(i),
                Created_Date__c = Date.today().addDays(-i),
                Customer_Account__c = testAccount.Id,
                Order_Paid_Total__c = 4.5 * i,
                Order_Sub_Total__c = 3.5 * i,
                Order_Tax_Total__c = 2.5 * i,
                Order_Total__c = 1.5 * i
        );
    }
}