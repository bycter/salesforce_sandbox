public with sharing class AttachmentTriggerHandler extends TriggerHandler {
    public override void afterInsert() {
        QuoteAttachmentUtils.associateAttachmentFromQuoteDocumentsWithRelatedContract((List<Attachment>) Trigger.new);
        QuoteAttachmentUtils.copyAttachmentFromQuoteDocumentToSecureObject(Trigger.new);
    }
    public override void afterUpdate() {
        QuoteAttachmentUtils.associateAttachmentFromQuoteDocumentsWithRelatedContract((List<Attachment>) Trigger.new);
        QuoteAttachmentUtils.copyAttachmentFromQuoteDocumentToSecureObject(Trigger.new);
    }
}