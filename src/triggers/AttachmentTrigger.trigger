trigger AttachmentTrigger on Attachment (after insert, after update) {
    new AttachmentTriggerHandler().run();
}