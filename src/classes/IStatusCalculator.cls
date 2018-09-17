/**
 * @description Interface for all Opportunity Status Calculator classes
 */
public interface IStatusCalculator {

	String calculateNewStatus(Opportunity theOpportunity);
}