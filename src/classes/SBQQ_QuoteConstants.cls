/**
 * @description Constants related to SBQQ_Quote and linked functionality
 */
public with sharing class SBQQ_QuoteConstants {

    public static final String QUOTE_LINE_STATUS_PENDING = 'Pending';
    public static final String QUOTE_LINE_STATUS_COMPLETE = 'Complete';

    public static final String STATUS_SIGNED = 'Signed';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_VOIDED = 'Voided';
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_IN_REVIEW = 'In Review';
    public static final String STATUS_REJECTED = 'Rejected';
    public static final String STATUS_APPROVED = 'Approved';
    public static final String STATUS_ACCEPTED = 'Accepted';
    public static final String STATUS_OBSOLETE = 'Obsolete';
    public static final String STATUS_PENDING_APPROVAL_OFFLINE_EDIT = 'Pending Approval - Offline Edit';
    public static final String STATUS_AWAITING_APPROVAL_OFFLINE_EDIT = 'Awaiting Approval - Offline Edit';

    public static final String CONVENTIONAL_RECORD_TYPE = 'Conventional';
    public static final String CONVENTIONAL_LOCKED_RECORD_TYPE = 'Conventional_Locked';
    public static final String SERVICED_RECORD_TYPE = 'Serviced';
    public static final String SERVICED_LOCKED_RECORD_TYPE = 'Serviced_Locked';
    public static final String VIRTUAL_RECORD_TYPE = 'Virtual';
    public static final String VIRTUAL_LOCKED_RECORD_TYPE = 'Virtual_Locked';
    public static final String MEETING_ROOMS_RECORD_TYPE = 'Meeting Rooms';


    //We cannot withdraw documents with some statuses from DocuSign (It's the limitation of DocuSign)
    public static final Set<String> NOT_WITH_DRAWING_SIGNATURE_STATUSES = new Set<String>{
            STATUS_SIGNED,
            STATUS_COMPLETED,
            STATUS_VOIDED
    };

    public static final String CONTACT_TYPE_LC = 'Legal Contact';
    public static final String CONTACT_TYPE_PMC = 'Project Management Contact';
    public static final String CONTACT_TYPE_ILPC = 'In Life Property Contact';
    public static final String CONTACT_TYPE_OOHC = 'Out of Hours Contact';
    public static final String CONTACT_TYPE_BC = 'Billing Contact';
    public static final String CONTACT_TYPE_CD = 'Director Contact';
    public static final Integer DUE_DATE_ESTIMATION = 30;

    public static final String BILLINGFREQUENCY_WEEKLY = 'Weekly';
    public static final String BILLINGFREQUENCY_MONTHLY = 'Monthly';
    public static final String BILLINGFREQUENCY_QUARTERLY = 'Quarterly';
    public static final String BILLINGFREQUENCY_SEMIANNUAL = 'Semiannual';
    public static final String BILLINGFREQUENCY_ANNUAL = 'Annual';
    public static final String BILLINGFREQUENCY_TRADITIONAL_QUARTERS = 'Traditional Quarters';
    public static final String BILLINGFREQUENCY_ONE_TIME = 'One-Time';
    public static final String BILLINGFREQUENCY_UPFRONT = 'Up Front';
    public static final String BILLINGFREQUENCY_PARTIALUPFRONT = 'Partial Up Front';

    public static final String STATUS_SIGNATURE_COMPLETE = 'Completed';

    public static final Map<String, String> CONTACT_TYPE_TO_PREFIX_MAP = new Map<String, String>{
            CONTACT_TYPE_LC => 'LC',
            CONTACT_TYPE_PMC => 'PMC',
            CONTACT_TYPE_ILPC => 'ILPC',
            CONTACT_TYPE_OOHC => 'OOHC',
            CONTACT_TYPE_BC => 'BC'
    };

    public static final Map<String, String> PREFIX_TO_CONTACT_TYPE_MAP = new Map<String, String>{
            'LC' => CONTACT_TYPE_LC,
            'PMC' => CONTACT_TYPE_PMC,
            'ILPC' => CONTACT_TYPE_ILPC,
            'OOHC' => CONTACT_TYPE_OOHC,
            'BC' => CONTACT_TYPE_BC
    };

    public static final Map<String, String> FIELD_NAMES_MAP = new Map<String, String>{
            'First_Name__c' => 'FirstName',
            'Last_Name__c' => 'LastName',
            'Email__c' => 'Email',
            'Phone__c' => 'Phone',
            'Mobile__c' => 'MobilePhone',
            'Contact_Preference__c' => 'Contact_Preference__c'
    };

    //Quote Types
    public static final String TYPE_RENEWAL = 'Renewal';

    //Quote Portfolios
    public static final String DEFAUL_PORTFOLIO_NAME = 'Bruntwood';
}