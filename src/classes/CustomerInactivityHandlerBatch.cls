/**
 * A batch apex class what close Opportunities with no any customer activity at set of period time.
 * It process a lot of Opportunities at a time.
 *
 * @author v2.nareyko
 * @since 9/1/18
 */

global without sharing class CustomerInactivityHandlerBatch implements Database.Batchable<sObject> {

    private String query;

    global CustomerInactivityHandlerBatch(String query) {
        this.query = query;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        for(Opportunity opportunity : scope) {
            closeInactiveOpportunity(opportunity);
        }
        update scope;
    }

    global void finish(Database.BatchableContext param1) {}

    private void closeInactiveOpportunity(Opportunity opportunity) {
        opportunity.Closed_Lost_Reason__c = 'Inactivity';
        opportunity.StageName = 'Closed Lost';
        opportunity.CloseDate = System.now().date();
        opportunity.Closed_Lost_Date__c = System.now().date();
    }
}