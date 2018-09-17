trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert, after delete) {
    new ContentDocumentLinkHandler().run();
}