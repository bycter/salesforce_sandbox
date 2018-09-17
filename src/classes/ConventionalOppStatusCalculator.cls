/**
 * @description Opportunity Status Calculator for Conventional Sales Record Type
 */
public with sharing class ConventionalOppStatusCalculator implements IStatusCalculator {

	private static final String STAGE_QUALIFIED = 'Qualified'; //TODO: move Stages to one place
	private static final String STAGE_VIEWVING = 'Viewing';
	private static final String STAGE_TERMS_OUT = 'Terms Out';
	public static final String STAGE_INSTRUCTED = 'Instructed';
	public static final String STAGE_EXCHANGED = 'Exchanged';
	public static final String STAGE_COMPLETED = 'Completed';
	public static final String STAGE_LOST = 'Closed Lost';

	/**
	 * @description Calculated Opportunity status
	 */
	public String calculateNewStatus(Opportunity theOpportunity) {
		String newStatus = STAGE_QUALIFIED;
		if ( theOpportunity.Viewing_Count__c > 0 ) {
			newStatus = STAGE_VIEWVING;
		}
		if ( theOpportunity.HOTs_Sent__c ) {
			newStatus = STAGE_TERMS_OUT;
		}
		if ( theOpportunity.HOTs_Sent__c && theOpportunity.HOTs_Signed__c ) {
			newStatus = STAGE_INSTRUCTED;
		}
		if ( theOpportunity.HOTs_Sent__c && theOpportunity.HOTs_Signed__c && theOpportunity.Contracts_Exchanged__c ) {
			newStatus = STAGE_EXCHANGED;
		}
		if ( theOpportunity.HOTs_Sent__c && theOpportunity.HOTs_Signed__c && theOpportunity.Contracts_Exchanged__c
			&& theOpportunity.Contract_Activated__c && theOpportunity.LT_Case_Completed__c ) {
			newStatus = STAGE_COMPLETED;
		}
		if ( String.isNotBlank(theOpportunity.Closed_Lost_Reason__c) ) {
			newStatus = STAGE_LOST;
		}
		return newStatus;
	}
}