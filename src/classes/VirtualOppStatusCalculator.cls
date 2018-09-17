/**
 * @description Opportunity Status Calculator for Virtual Sales Record Type
 */
public with sharing class VirtualOppStatusCalculator implements IStatusCalculator  {

	private static final String STAGE_QUALIFIED = 'Qualified';
	private static final String STAGE_MEETING_BOOKED = 'Meeting Booked';
	private static final String STAGE_CHECK_COMPLETE = 'Check Complete';
	private static final String STAGE_TERMS_AGREED = 'Terms Agreed';
	private static final String STAGE_COMPLETED = 'Completed';
	private static final String STAGE_LOST = 'Closed Lost';

	/**
	 * @description Calculated Opportunity status
	 */
	public String calculateNewStatus(Opportunity theOpportunity) {
		String newStatus = STAGE_QUALIFIED;
		if ( theOpportunity.Event_Count__c > 0 ) {
			newStatus = STAGE_MEETING_BOOKED;
		}
		Boolean complianceCheckComplete = theOpportunity.Compliance_Check_Complete__c == 'Yes' || (theOpportunity.Compliance_Check_Complete__c == 'No' && theOpportunity.Virtual_Compliance_Approval_Complete__c);
		if ( complianceCheckComplete ) {
			newStatus = STAGE_CHECK_COMPLETE;
		}
		if ( complianceCheckComplete && String.isNotBlank(theOpportunity.Briefing_Statement__c) && theOpportunity.HOTs_Signed__c ) {
			newStatus = STAGE_TERMS_AGREED;
		}
		if ( complianceCheckComplete && String.isNotBlank(theOpportunity.Briefing_Statement__c) && theOpportunity.HOTs_Signed__c && theOpportunity.Deposit_Paid__c ) {
			newStatus = STAGE_COMPLETED;
		}
		if ( String.isNotBlank(theOpportunity.Closed_Lost_Reason__c) ) {
			newStatus = STAGE_LOST;
		}
		return newStatus;
	}
}