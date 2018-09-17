@isTest
public class ConventionalTermDocumentGeneratorTest {

    @isTest static void generateConventionalTermDocument() {

        SBQQ__Quote__c quote = RecordDmlTest.generateConventionalQuoteWithLines(QuoteProductCodes.OFFICE_RENT);
        Account acc = [
                SELECT Id, BillingStreet, BillingCity, BillingPostalCode, BillingCountry
                FROM Account
                WHERE Id = :quote.SBQQ__Account__c
        ];
        String address = '';
        address = String.isNotBlank(acc.BillingStreet) ? acc.BillingStreet + ' ' : '';
        address += String.isNotBlank(acc.BillingCity) ? acc.BillingCity + ' ' : '';
        address += String.isNotBlank(acc.BillingPostalCode) ? acc.BillingPostalCode + ' ' : '';
        address += String.isNotBlank(acc.BillingCountry) ? acc.BillingCountry : '';

        List<SBQQ__QuoteLine__c> qliList = [
                SELECT Id, Name, Break_Date__c, Minimum_Notice__c, Maximum_Notice__c, Break_Penalty__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :quote.Id AND SBQQ__Product__r.Hot_Type__c = 'CustomerBreakOption'
        ];

        Test.StartTest();
        ApexPages.currentPage().getParameters().put('id', String.valueOf(quote.Id));
        ConventionalTermDocumentGenerator testTermDoc = new ConventionalTermDocumentGenerator();
        testTermDoc.init();
        System.assertEquals(address, testTermDoc.getAccountFullAddress());
        System.assertEquals(0, testTermDoc.getNumCarParking(ProductService.PRODUCT_CODE_CAR_PARKING_LICENSE));
        testTermDoc.getMapBreakOptions(QuoteProductCodes.CUSTOMER_BREAK_OPTION);
        testTermDoc.getMapBreakOptions(QuoteProductCodes.SUPPLIER_BREAK_OPTION);
        Test.StopTest();

    }

}