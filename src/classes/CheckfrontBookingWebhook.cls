/**
 * @description Rest API class to accept information from Checkfront
 */
@RestResource(urlMapping='/CheckfrontWebhookBookingModified')
global with sharing class CheckfrontBookingWebhook {

    @HttpPost
    global static void doPost() {
        RestRequest request = RestContext.request;
        try {
            String requestBody = request.requestBody.toString();
            if ( String.isNotBlank(requestBody) ) {
                CheckfrontDTO.CheckfrontRequest requestData = (CheckfrontDTO.CheckfrontRequest)JSON.deserialize(requestBody, CheckfrontDTO.CheckfrontRequest.class);
                if ( requestData.booking != null ) {
                    System.debug('insert');
                    insert requestData.booking.convertToSObject();
                }
            }
        } catch ( Exception ex ) {
            System.debug('*** CheckfrontWebhookBookingModified Exception: ' + ex.getMessage());
        }
    }
}