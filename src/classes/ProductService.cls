public with sharing class ProductService {
//    TODO: move codes to one place
    public static final String PRODUCT_CODE_SERVICE_CHARGE = 'ServiceCharge';
    public static final String PRODUCT_CODE_SERVICE_CHARGE_CAP = 'ServiceChargeCap';
    public static final String PRODUCT_CODE_OFFICE_RENT = 'OfficeRent';
    public static final String PRODUCT_CODE_LAB_SPACE = 'LabSpace';
    public static final String PRODUCT_CODE_RETAIL_RENT = 'RetailRent';
    public static final String PRODUCT_CODE_STORAGE = 'Storage';
    public static final String PRODUCT_CODE_HALF_RENT = 'HalfRent';
    public static final String PRODUCT_CODE_CAR_PARKING_LICENSE = 'CarParkLicense';
    public static final String PRODUCT_CODE_CAR_SPACE = 'CarSpace';
    public static final String PRODUCT_CODE_CAR_PARKING_LEASE = 'CarParkingLease';
    public static final String PRODUCT_CODE_DEPOSIT_RETAIN = 'DepositRetain';
    public static final String PRODUCT_CODE_PRE_EMPTION_AGREEMENT = 'PreEmptionAgreement';
    public static final String PRODUCT_CODE_DEPOSIT = 'BSDP';
    public static final String PRODUCT_CODE_FULL_VIRTUAL = 'BVLF';
    public static final String PRODUCT_CODE_MAIL_VIRTUAL = 'BVLM';
    public static final String PRODUCT_CODE_STEPPED_RENT = 'SteppedRent';
    public static final String PRODUCT_CODE_FREE_RENT = 'RentFree';
    public static final String PRODUCT_CODE_RENT_REVIEW = 'RentReview';
    public static final String PRODUCT_CODE_SERVICED = 'BSLF';
    public static final String PRODUCT_CODE_REFURBISHMENT_SUPPLIER = 'RefurbishmentSupplier'; //CAT A Refurbishment by Supplier
    public static final String PRODUCT_CODE_REFURBISHMENT_CUSTOMER = 'RefurbishmentCustomer'; //CAT A Refurbishment by Customer
    public static final String PRODUCT_CODE_FIT_OUT_SUPPLIER = 'FitOut'; //CAT B Fit-Out by Supplier
    public static final String PRODUCT_CODE_FIT_OUT_CUSTOMER = 'FitOutCustomer'; //CAT B Fit-Out by Customer;
    public static final String PRODUCT_CODE_CUSTOMER_BREAK = 'CustomerBreakOption';
    public static final String CAR_PARKING_LICENCE_CODE = 'BCLC';
    public static final String CALL_HANDLING_CODE = 'BVCH';

    public static final String PRODUCT_FAMILY_SUITE = 'suite';
    public static final String PRODUCT_FAMILY_PARKING = 'Car space';

    public static Boolean isSuite(Product2 product) {
        String prodFamily = (String) product.get('Family');
        return String.isNotBlank(prodFamily) && prodFamily.equalsIgnoreCase(PRODUCT_FAMILY_SUITE);
    }
}