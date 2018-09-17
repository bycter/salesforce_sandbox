public class PostDeploySetup {

    public static final String CUSTOMER_INACTIVITY_SCHEDULED_JOB_NAME = 'Inactive Opportunities closing';
    public static final String CUSTOMER_INACTIVITY_CRON_EXPRESSION = '0 0 1 * * ?';
    public static final Integer CUSTOMER_INACTIVITY_EXPIRATION_TIME = 180;
    public static final String VIEWING_FEEDBACK_SCHEDULED_JOB_NAME = 'ScheduledViewingFeedbackEmailSending';
    public static final String VIEWING_FEEDBACK_CRON_EXPRESSION = '0 0 12 * * ?';

    public static void setup() {
        setUpCustomerInactivityCustomSettings();
        scheduleClosingInactiveOpportunities();
        scheduleViewingFeedbackEmailSending();
        createAssesManagementChatterGroup();
        createCaseTeamMemberRole();
    }

    public static void setupCaseTeam() { //need it separately due to mixed dml restrictions
        createLTCaseTeam();
    }

    public static void assignRTToPriceBooks() {
        List<Pricebook2> priceBooks = [select id, Name, RecordTypeId from Pricebook2 where isStandard = false];
        for (Pricebook2 pricebook : priceBooks) {
            RecordTypeInfo rtInfo = Schema.SObjectType.Pricebook2.getRecordTypeInfosByName().get(pricebook.Name.remove(' Sales'));
            pricebook.RecordTypeId = rtInfo == null ? null : rtInfo.getRecordTypeId();
        }
        update priceBooks;
    }

    public static void cleanConfigurationAttributesFields() {
        List<SBQQ__ConfigurationAttribute__c> cas = [select Id, SBQQ__DEFAULTOBJECT__C, SBQQ__DEFAULTFIELD__C from SBQQ__ConfigurationAttribute__c];
        for (SBQQ__ConfigurationAttribute__c ca : cas) {
            ca.SBQQ__DEFAULTOBJECT__C = null;
            ca.SBQQ__DEFAULTFIELD__C = null;
        }
        update cas;
    }

    private static void scheduleClosingInactiveOpportunities() {
        if (isJobNotExist(CUSTOMER_INACTIVITY_SCHEDULED_JOB_NAME)) {
            CustomerInactivityScheduledHandler cish = new CustomerInactivityScheduledHandler();
            System.schedule(CUSTOMER_INACTIVITY_SCHEDULED_JOB_NAME, CUSTOMER_INACTIVITY_CRON_EXPRESSION, cish);
        }
    }

    private static void setUpCustomerInactivityCustomSettings() {
        if (customerInactivitySettingNotExist()) {
            CustomerInactivitySettings__c newInstance = new CustomerInactivitySettings__c();
            newInstance.Name = CustomerInactivityScheduledHandler.INSTANCE_INACTIVITY_EXP_TIME;
            newInstance.Inactivity_Expiration_Time__c = CUSTOMER_INACTIVITY_EXPIRATION_TIME;
            insert newInstance;
        }
    }

    private static void scheduleViewingFeedbackEmailSending() {
        if (isJobNotExist(VIEWING_FEEDBACK_SCHEDULED_JOB_NAME)) {
            ScheduledViewingFeedbackEmailSending scheduledJob = new ScheduledViewingFeedbackEmailSending();
            System.schedule(VIEWING_FEEDBACK_SCHEDULED_JOB_NAME, VIEWING_FEEDBACK_CRON_EXPRESSION, scheduledJob);
        }
    }

    private static void createAssesManagementChatterGroup() {
        if (isAssesManagementChatterGroupNotExist()) {
            CollaborationGroup assetManagementChatterGroup =
                    new CollaborationGroup(Name = Constants.ASSET_MANAGEMENT_CHATTER_GROUP_NAME,
                            CollaborationType = 'Private');
            try {
                insert assetManagementChatterGroup;
            } catch (Exception e) {
                //do nothing it fails during tests run only TODO: find a way to fix https://developer.salesforce.com/forums/?id=906F0000000BMY8IAO
            }
        }
    }

    private static void createCaseTeamMemberRole() {
        if ([select id from CaseTeamRole where Name = :'Default'].size() == 0) {
            CaseTeamRole ltCaseRole = new CaseTeamRole(Name = 'Default', AccessLevel = 'Edit');
            try {
                insert ltCaseRole;
            } catch (Exception e) {
                System.debug(e);
                //do nothing it fails during tests run only TODO: find a way to test
            }
        }
    }

    private static void createLTCaseTeam() {
        if ([select id from CaseTeamTemplate where Name = :CaseTriggerHandler.LEASE_TRANSACTION_CASE_TEAM].size() == 0) {
            CaseTeamTemplate ltCaseTeam = new CaseTeamTemplate(Name = CaseTriggerHandler.LEASE_TRANSACTION_CASE_TEAM);
            insert ltCaseTeam;
        }
    }

    private static Boolean isJobNotExist(String jobName) {
        List<sObject> jobs = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
        ];
        return jobs.size() == 0;
    }

    private static Boolean customerInactivitySettingNotExist() {
        return null == CustomerInactivitySettings__c.getInstance(
                CustomerInactivityScheduledHandler.INSTANCE_INACTIVITY_EXP_TIME);
    }

    private static Boolean isAssesManagementChatterGroupNotExist() {
        CollaborationGroup[] assesManagementChatterGroup = [
                Select g.Name
                From CollaborationGroup g
                where g.Name = :Constants.ASSET_MANAGEMENT_CHATTER_GROUP_NAME
                limit 1
        ];
        return assesManagementChatterGroup.size() == 0;
    }
}