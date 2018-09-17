public virtual class QuoteDocumentParams {
    public static String SEND_FOR_KEY_NAME { get; set; }
    public static final String SIGNATURE { get; set; }
    public static final String REVIEW { get; set; }
    public static final String GENERATE_OFFLINE_DOCUMENT { get; set; }
    public static final String SEND_OFFLINE_DOCUMENT { get; set; }
    static {
        SEND_FOR_KEY_NAME = 'sendFor';
        SIGNATURE = 'signature';
        REVIEW = 'review';
        GENERATE_OFFLINE_DOCUMENT = 'generateOfflineDocument';
        SEND_OFFLINE_DOCUMENT = 'sendOfflineDocument';
    }
}