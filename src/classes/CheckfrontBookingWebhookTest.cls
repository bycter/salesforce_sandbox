/**
 * @description Test class for CheckfrontBookingWebhook class
 */
@isTest
private class CheckfrontBookingWebhookTest {

    private static final String BOOKING_WEBHOOK_DATA = '{"@attributes":{"version":"3.21.0.38","host":"bruntwooddev.checkfront.com"},' +
            '"booking":{"@attributes":{"booking_id":"1"},' +
            '"status":"PEND",' +
            '"code":"HFHS-220318",' +
            '"tid":"demo",' +
            '"created_date":"1521710586",' +
            '"start_date":"1522281600",' +
            '"end_date":"1522540800",' +
            '"customer":{' +
            '"code":"HF6-953-306",' +
            '"name":"Test Customer",' +
            '"email":"test.customer@bruntwood.co.uk"},' +
            '"fields":{ "customer_name": "Test Customer",'+
            '"customer_email": "support@checkfront.com",' +
            '"customer_region": "BC",' +
            '"customer_address": "170-422 Richards Street",' +
            '"customer_city": "Vancouver",' +
            '"customer_country": "CA",' +
            '"customer_phone": "1 (800) 559-0985",' +
            '"customer_postal_zip": "V6B 2Z4",' +
            '"request": "Blue paddleboard if available, please."' +
            '},"meta":{"note":{},"customer_phone":{},"customer_postal_zip":{},' +
            '"customer_country":"BY","customer_city":{},"customer_region":{},' +
            '"customer_email":"test.customer@bruntwood.co.uk","customer_name":"Test Customer",' +
            '"customer_first_name":"Test","customer_last_name":"Customer","customer_address":{},"booking_language":"en"}' +
            ',"order":{"@attributes":{"currency_id":"BYR"},"sub_total":"297","tax_total":"0","paid_total":"100","total":"297"' +
            ',"taxes":{},"items":{"item":{"@attributes":{"line_id":"1","item_id":"1"},"start_date":"1522281600",' +
            '"end_date":"1522540800","sku":"sample-room-rooom","slip":{},"package_id":"0","status":"PEND","total":"297",' +
            '"tax_total":"0","qty":"1"}}}}}';

    @isTest
    private static void testDoPost() {
        //given
        RestContext.request = new RestRequest();
        RestContext.response = new RestResponse();

        RestContext.request.requestURI = '/services/apexrest/CheckfrontWebhookBookingModified';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.addHeader('Content-Type', 'application/json');

        RestContext.request.requestBody = Blob.valueOf(BOOKING_WEBHOOK_DATA);

        //when
        CheckfrontBookingWebhook.doPost();

        //then
        List<Meeting_Room_Booking__c> bookings = [SELECT Code__c, Status__c, Customer_Name__c
                                                  FROM Meeting_Room_Booking__c];
        System.assertNotEquals(true, bookings.isEmpty());
        System.assertEquals('HFHS-220318', bookings[0].Code__c);
        System.assertEquals('PEND', bookings[0].Status__c);
        System.assertEquals('Test Customer', bookings[0].Customer_Name__c);

    }
}