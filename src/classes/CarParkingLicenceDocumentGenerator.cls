public class CarParkingLicenceDocumentGenerator {

    public static final String CAR_PARKING_LICENSE_PRODUCT_CODE = 'CarParkLicense';
    public static final String CAR_SPACE_PRODUCT_CODE = 'CarSpace';
    public SBQQ__Quote__c quote { get; set; }
    public List<SBQQ__QuoteLine__c> carParkingLicensesAndSpaces { get; set; }
    public SBQQ__QuoteLine__c carParkingLicense { get; set; }
    public Integer carParkingSpacesQuantity { get; set; }

    public CarParkingLicenceDocumentGenerator() {
        Id quoteId = (Id) ApexPages.currentPage().getParameters().get('id');
        carParkingSpacesQuantity = 0;
        if (quoteId != NULL) {
            quote = [
                    SELECT Id, Property__r.Company_Name__c, SBQQ__Account__r.Registered_Name__c,
                            Property__r.Name, Property__r.Company_Logo__c,
                            Property__r.Company_Address__c, SBQQ__Account__r.ShippingStreet,
                            SBQQ__Account__r.ShippingCity, SBQQ__Account__r.ShippingPostalCode,
                            BW_Signature__r.Name
                    FROM SBQQ__Quote__c
                    WHERE Id = :quoteId
            ];
        }
        carParkingLicensesAndSpaces = [
                SELECT Id, New_Annual_Average__c, Start_Date__c, Term__c,
                        SBQQ__ProductCode__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quoteId
                AND (SBQQ__ProductCode__c = :CAR_PARKING_LICENSE_PRODUCT_CODE
                        OR SBQQ__ProductCode__c = :CAR_SPACE_PRODUCT_CODE)
        ];
        calculateTotalAnnualAverageAndQuantity(carParkingLicensesAndSpaces);
    }

    private void calculateTotalAnnualAverageAndQuantity(List<SBQQ__QuoteLine__c> carParkingLicenseSpaceList) {
        for (SBQQ__QuoteLine__c carParkingLicenseSpace : carParkingLicenseSpaceList) {
            if (carParkingLicenseSpace.SBQQ__ProductCode__c == CAR_PARKING_LICENSE_PRODUCT_CODE) {
                carParkingLicense = carParkingLicenseSpace;
            } else {
                carParkingSpacesQuantity += 1;
            }
        }
    }
}