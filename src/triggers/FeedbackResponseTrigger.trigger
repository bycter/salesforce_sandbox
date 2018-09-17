trigger FeedbackResponseTrigger on Feedback_Response__c (after insert) {
    new Feedback_ResponseTriggerHandler().run();
}