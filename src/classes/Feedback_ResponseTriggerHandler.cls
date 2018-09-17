/**
 * Trigger handler that creates Customer Feedbacks from Feedback Response.
 */
public with sharing class Feedback_ResponseTriggerHandler extends TriggerHandler {
    public override void afterInsert() {
        CustomerFeedbackService.createFeedbacks(Trigger.new);
    }
}