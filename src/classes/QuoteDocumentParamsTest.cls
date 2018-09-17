@IsTest
public class QuoteDocumentParamsTest {
    @IsTest
    public static void testDocumentParams() {
        System.assertEquals(QuoteDocumentParams.SEND_FOR_KEY_NAME, QuoteDocumentParams.SEND_FOR_KEY_NAME);
        System.assertEquals(QuoteDocumentParams.SIGNATURE, QuoteDocumentParams.SIGNATURE);
        System.assertEquals(QuoteDocumentParams.REVIEW, QuoteDocumentParams.REVIEW);
    }
}