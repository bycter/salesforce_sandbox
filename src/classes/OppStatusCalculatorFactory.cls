/**
 * @description Factory that returns concrete Opportunity Status Calculator implementation based on Record Type
 */
public with sharing class OppStatusCalculatorFactory {
	
	private static IStatusCalculator conventionalStatusCalculator;
	private static IStatusCalculator servicedStatusCalculator;
	private static IStatusCalculator virtualStatusCalculator;

	/**
	 * @description Returns implementation of Opportunity Status Calculator
	 */
	public static IStatusCalculator getStatusCalculator(Id opportunityRecordTypeId) {
		if ( opportunityRecordTypeId == OpportunityService.CONVENTIONAL_RECORD_TYPE_ID ) {
			if ( conventionalStatusCalculator == null ) {
				conventionalStatusCalculator = new ConventionalOppStatusCalculator();
			}
			return conventionalStatusCalculator;
		} else if ( opportunityRecordTypeId == OpportunityService.SERVICED_RECORD_TYPE_ID ) {
			if ( servicedStatusCalculator == null ) {
				servicedStatusCalculator = new ServicedOppStatusCalculator();
			}
			return servicedStatusCalculator;
		} else if ( opportunityRecordTypeId == OpportunityService.VIRTUAL_RECORD_TYPE_ID ) {
			if ( virtualStatusCalculator == null ) {
				virtualStatusCalculator =  new VirtualOppStatusCalculator();
			}
			return virtualStatusCalculator;
		}
		return null;
	}
}