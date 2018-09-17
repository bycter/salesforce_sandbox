public with sharing class CreateAdHocRecordsController {
    public static final String ERROR_MESSAGE = 'An Ad-hoc Revenue record has already been created for the selected meeting room booking';
    public static final String TAX_CODE_NAME = 'GB-O-STD';
    public static final String COMPANY_NAME = 'Bruntwood Meeting Rooms Limited';

    public List<MeetingPaymentInfo> adHocRecords { get; set; }

    private Set<Id> recordIds;

    public CreateAdHocRecordsController(ApexPages.StandardSetController stdSetController) {
        List<Meeting_Room_Booking__c> selectedRecords = (List<Meeting_Room_Booking__c>) stdSetController.getSelected();
        this.recordIds = new Map<Id, sObject>(selectedRecords).keySet();
        this.adHocRecords = new List<MeetingPaymentInfo>();
    }

    public CreateAdHocRecordsController(ApexPages.StandardController stdController) {
        this.recordIds = new Set<Id>{
                stdController.getId()
        };
        this.adHocRecords = new List<MeetingPaymentInfo>();
    }

    public PageReference createRecords() {
        PageReference thePage;
        this.adHocRecords = this.createAdHocRecords(this.recordIds);

        if (this.adHocRecords.size() == 1 && !this.adHocRecords.get(0).hasError()) {
            thePage = new PageReference('/' + this.adHocRecords.get(0).adHocRecord.Id);
            thePage.setRedirect(true);
        }
        return thePage;
    }

    private List<MeetingPaymentInfo> createAdHocRecords(Set<Id> meetingIds) {
        List<Meeting_Room_Booking__c> meetings = this.getMeetingRoomPayments(meetingIds);
        C2G__codaTaxCode__c taxCode = this.getTaxCode();
        C2G__codaCompany__c company = this.getCompany();

        Map<Id, MeetingPaymentInfo> outputMap = new Map<Id, MeetingPaymentInfo>();
        List<Ad_hoc_Revenue__c> adHocRecords = new List<Ad_hoc_Revenue__c>();
        List<Id> meetingIdsToUpdate = new List<Id>();

        for (Meeting_Room_Booking__c meeting : meetings) {
            MeetingPaymentInfo info = new MeetingPaymentInfo(meeting);
            outputMap.put(meeting.Id, info);

            if (!info.hasError()) {
                Ad_hoc_Revenue__c adHocRecord = this.generateAdHocRecord(meeting, taxCode, company);
                info.adHocRecord = adHocRecord;
                adHocRecords.add(adHocRecord);
                meetingIdsToUpdate.add(meeting.Id);
            }
        }

        List<Meeting_Room_Booking__c> meetingRoomsToUpdate = new List<Meeting_Room_Booking__c>();
        List<Database.SaveResult> saveResults = Database.insert(adHocRecords, false);
        for (Integer order = 0; order < saveResults.size(); order++) {
            Database.SaveResult sr = saveResults.get(order);
            Id meetingId = meetingIdsToUpdate.get(order);

            if (!sr.isSuccess()) {
                List<String> errs = new List<String>();
                for (Database.Error err : sr.getErrors()) {
                    errs.add(err.getMessage());
                }
                outputMap.get(meetingId).message = String.join(errs, '\n');
            } else {
                outputMap.get(meetingId).meeting.Ad_hoc_Revenue__c = sr.getId();
                meetingRoomsToUpdate.add(outputMap.get(meetingId).meeting);
            }
        }
        update meetingRoomsToUpdate;
        return outputMap.values();
    }

    private Ad_hoc_Revenue__c generateAdHocRecord(Meeting_Room_Booking__c meeting, C2G__codaTaxCode__c taxCode, C2G__codaCompany__c company) {
        Date createdDate = meeting.Created_Date__c != null ? meeting.Created_Date__c.date() : null;

        return new Ad_hoc_Revenue__c(
                Legal_Entity__c = company.Name,
                Customer_Account__c = meeting.Customer_Account__c,
                Customer_Reference__c = meeting.Code__c,
                CurrencyIsoCode = meeting.CurrencyIsoCode,
                Currency__c = 'GBP',
                //Property__c = tempProperty.Id, //TODO: will be implemented after Tobie answer in 1628 story
                Due_Date__c = createdDate,
                Invoice_Date__c = createdDate,
                //Invoice_Description__c = 'Invoice Description', //TODO: will be implemented after Tobie answer in 1628 story
                //Period__c = 'Period', //TODO: will be implemented after Tobie answer in 873 and 1628 story
                //Product__c = tempProduct2.Id, //TODO: will be implemented after Tobie answer in 1628 story
                Quantity__c = 1.0,
                Unit_Price__c = meeting.Order_Paid_Total__c,
                //Document_Type__c = 'Invoice', //TODO: will be implemented after Tobie answer in 1628 story
                //From_Date__c = Date.today(), //TODO: will be implemented after Tobie answer in 1628 story
                //To_Date__c = Date.today() //TODO: will be implemented after Tobie answer in 1628 story
                Tax_Code__c = taxCode.Name
        );
    }

    private List<Meeting_Room_Booking__c> getMeetingRoomPayments(Set<Id> meetingIds) {
        return [
                SELECT Id, Name, CurrencyIsoCode, Code__c, Created_Date__c, Customer_Email__c, Customer_Name__c, Order_Paid_Total__c,
                        Order_Sub_Total__c, Order_Tax_Total__c, Order_Total__c, Status__c, Customer_Account__c, Ad_hoc_Revenue__c
                FROM Meeting_Room_Booking__c
                WHERE Id IN:meetingIds
        ];
    }

    private C2G__codaTaxCode__c getTaxCode() {
        C2G__codaTaxCode__c record = new C2G__codaTaxCode__c();
        List<C2G__codaTaxCode__c> taxCodes = [
                SELECT Id, Name, c2g__ExternalId__c
                FROM C2G__codaTaxCode__c
                WHERE Name = :TAX_CODE_NAME
                LIMIT 1
        ];
        if (!taxCodes.isEmpty()) {
            record = taxCodes.get(0);
        }
        return record;
    }

    private C2G__codaCompany__c getCompany() {
        C2G__codaCompany__c company = new C2G__codaCompany__c();
        List<C2G__codaCompany__c> companies = [SELECT Id, Name FROM C2G__codaCompany__c WHERE Name = :COMPANY_NAME];
        if (!companies.isEmpty()) {
            company = companies.get(0);
        }
        return company;
    }

    public class MeetingPaymentInfo {
        public Meeting_Room_Booking__c meeting { get; set; }
        public Ad_hoc_Revenue__c adHocRecord { get; set; }
        public String message { get; set; }

        public MeetingPaymentInfo(Meeting_Room_Booking__c meeting) {
            this.meeting = meeting;
            if (this.meeting.Ad_hoc_Revenue__c != null) {
                this.message = ERROR_MESSAGE;
            }
        }

        public Boolean hasError() {
            return String.isNotBlank(this.message);
        }
    }
}