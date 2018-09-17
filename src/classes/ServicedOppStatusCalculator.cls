/**
 * @description Opportunity Status Calculator for Serviced Sales Record Type
 */
public with sharing class ServicedOppStatusCalculator implements IStatusCalculator {

	private static final String STAGE_QUALIFIED = 'Qualified';
	private static final String STAGE_VIEWVING = 'Viewing';
	private static final String STAGE_LICENSE_OUT = 'Licence Out';
	private static final String STAGE_COMPLETED = 'Completed';
	private static final String STAGE_LOST = 'Closed Lost';

	/**
	 * @description Calculated Opportunity status
	 */
	public String calculateNewStatus(Opportunity theOpportunity) {
		String newStatus = STAGE_QUALIFIED;
		if ( theOpportunity.Viewing_Count__c > 0 ) {
			newStatus = STAGE_VIEWVING;
		}
		if ( theOpportunity.LA_Sent__c ) {
			newStatus = STAGE_LICENSE_OUT;
		}
		if ( theOpportunity.LA_Sent__c &&  theOpportunity.LA_Signed__c && theOpportunity.Primary_Quote_Accepted__c) {
			newStatus = STAGE_COMPLETED;
		}
		if ( String.isNotBlank(theOpportunity.Closed_Lost_Reason__c) ) {
			newStatus = STAGE_LOST;
		}
		return newStatus;
	}

}