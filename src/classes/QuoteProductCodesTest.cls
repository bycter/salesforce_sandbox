@isTest
public class QuoteProductCodesTest {
    @IsTest
    public static void testProductCodes() {
        System.assertEquals(QuoteProductCodes.CO_WORKING_DEDICATED_LICENCE_FEE, QuoteProductCodes.CO_WORKING_DEDICATED_LICENCE_FEE);
        System.assertEquals(QuoteProductCodes.CO_WORKING_HOT_DESK_LICENCE_FEE, QuoteProductCodes.CO_WORKING_HOT_DESK_LICENCE_FEE);
        System.assertEquals(QuoteProductCodes.SERVICE_LICENCE_FEE, QuoteProductCodes.SERVICE_LICENCE_FEE);
        System.assertEquals(QuoteProductCodes.DEPOSIT, QuoteProductCodes.DEPOSIT);
        System.assertEquals(QuoteProductCodes.CUSTOMER_NOTICE, QuoteProductCodes.CUSTOMER_NOTICE);
        System.assertEquals(QuoteProductCodes.STEPPED_RENT, QuoteProductCodes.STEPPED_RENT);
        System.assertEquals(QuoteProductCodes.CAR_PARKING_LICENSE, QuoteProductCodes.CAR_PARKING_LICENSE);
    }
}