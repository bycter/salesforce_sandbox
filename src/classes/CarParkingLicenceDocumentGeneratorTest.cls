@isTest
public class CarParkingLicenceDocumentGeneratorTest {
    @testSetup
    public static void initData() {
        SBQQ__Quote__c quote = RecordDmlTest.generateServicedQuoteWithLines();
    }

    @isTest
    static void givenSBQQ_Quote_whenDocumentGeneratorInstanceCreated_thenCarParkingLicensesShouldBeLoadedIntoDocumentGenerator() {
        //given
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        //when
        ApexPages.currentPage().getParameters().put('id', String.valueOf(quote.Id));
        CarParkingLicenceDocumentGenerator documentGenerator = new CarParkingLicenceDocumentGenerator();

        //then
        System.assert(documentGenerator.carParkingLicensesAndSpaces.size() > 0, 'Car Parking Licenses have not been loaded');
    }
}