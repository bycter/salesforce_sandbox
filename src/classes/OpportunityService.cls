public with sharing class OpportunityService {
    public static final String STATUS_MEETING_BOOKED = 'Meeting Booked';
    public static final String STATUS_TERMS_AGREED = 'Terms Agreed';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_INSTRUCTED = 'Instructed';
    public static final String STATUS_EXCHANGED = 'Exchanged';
    public static final String STATUS_QUALIFIED = 'Qualified';

    public static final String VIRTUAL_RECORD_TYPE_NAME = 'Virtual';
    public static final String CONVENTIONAL_RECORD_TYPE = 'Conventional';
    public static final String SERVICED_RECORD_TYPE = 'Serviced';
    public static final Id VIRTUAL_RECORD_TYPE_ID;
    public static final Id CONVENTIONAL_RECORD_TYPE_ID;
    public static final Id SERVICED_RECORD_TYPE_ID;

    static {
        Map<String, RecordTypeInfo> recordTypeInfosMap = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        VIRTUAL_RECORD_TYPE_ID = recordTypeInfosMap.get(VIRTUAL_RECORD_TYPE_NAME).getRecordTypeId();
        CONVENTIONAL_RECORD_TYPE_ID = recordTypeInfosMap.get(CONVENTIONAL_RECORD_TYPE).getRecordTypeId();
        SERVICED_RECORD_TYPE_ID = recordTypeInfosMap.get(SERVICED_RECORD_TYPE).getRecordTypeId();
    }

    private static Map<Id, RecordType> opportunityRecordTypes;
    public static Map<Id, RecordType> getRecrodTypes() {
        if (opportunityRecordTypes == null) {
            opportunityRecordTypes = new Map<Id, RecordType>(
                RecordTypeHelper.getRecordTypesForSObject(RecordTypeHelper.OPPORTUNITY_SOBJECT)
            );
        }
        return opportunityRecordTypes;
    }

    public static void createTaskForCoordinator(List<Opportunity> opportunities) {
        Map<Id, Opportunity> completedOpportunities = new Map<Id, Opportunity>();
        Map<String, Opportunity> meetingBookedOpportunities = new Map<String, Opportunity>();
        List<Task> tasksToCreate = new List<Task>();

        for (Opportunity theOpportunity: opportunities) {
            if (theOpportunity.StageName.equals(STATUS_COMPLETED) && theOpportunity.Deposit_Paid__c) {
                completedOpportunities.put(theOpportunity.Id, theOpportunity);
            }
            if (theOpportunity.StageName.equals(STATUS_MEETING_BOOKED) && theOpportunity.Last_Event_ID__c != null) {
                meetingBookedOpportunities.put(theOpportunity.Last_Event_ID__c, theOpportunity);
            }
        }

        if (!completedOpportunities.isEmpty()) {
            List<SBQQ__Quote__c> quotes = [SELECT Id, Name,
                        SBQQ__Opportunity2__c,
                        SBQQ__PrimaryContact__c,
                        SBQQ__PrimaryContact__r.Name,
                        Contract__c, Contract__r.StartDate,
                        Property__c,
                        Property__r.Serviced_Space_Coordinator__c
                    FROM SBQQ__Quote__c
                    WHERE SBQQ__Opportunity2__c IN :completedOpportunities.keySet() 
                        AND Property__r.Serviced_Space_Coordinator__c != null];

            for (SBQQ__Quote__c quote: quotes) {
                Id opportunityId = quote.SBQQ__Opportunity2__c;
                if (completedOpportunities.containsKey(opportunityId)) {
                    Opportunity theOpportunity = completedOpportunities.get(opportunityId);
                    tasksToCreate.add(TaskService.generateVirtualTask(theOpportunity, quote));
                }
            }
        }

        if (!meetingBookedOpportunities.isEmpty()) {
            List<Event> events = [
                SELECT Id, RecordTypeId, Property__c, Property__r.Serviced_Space_Coordinator__c, WhoId
                FROM Event
                WHERE Id IN: meetingBookedOpportunities.keySet()
                    AND Property__r.Serviced_Space_Coordinator__c != null
            ];

            for (Event theEvent: events) {
                Id eventID = theEvent.Id;

                if (meetingBookedOpportunities.containsKey(eventID)) {
                    Opportunity theOpportunity = meetingBookedOpportunities.get(eventID);
                    tasksToCreate.add(TaskService.generateVirtualMeetingTask(theOpportunity, theEvent));
                }
            }
        }
        insert tasksToCreate;
    }

    /**
     * @description Calculates Opportunity statuses
     */
    public static void calculateOpportunitiesStatuses(List<Opportunity> theOpportunities, Map<Id, Opportunity> theOldMap) {
        List<Opportunity> oppsForStatusCalculation = new List<Opportunity>();
        for ( Opportunity theOpportunity : theOpportunities ) {
            //Skip status calcualtion logic if manualy selected Lost status
            if ( theOldMap.get(theOpportunity.Id).StageName != theOpportunity.StageName && theOpportunity.StageName == ConventionalOppStatusCalculator.STAGE_LOST ) {
                continue;
            }
            oppsForStatusCalculation.add(theOpportunity);
        }
        calculateOpportunitiesStatuses(oppsForStatusCalculation);
    }

    /**
     * @description Calculates Opportunity statuses for specified Opportunities
     */
    public static void calculateOpportunitiesStatuses(List<Opportunity> theOpportunities) {
        Set<Id> automatedStatusCalculationRecordTypes = new Set<Id>{CONVENTIONAL_RECORD_TYPE_ID, SERVICED_RECORD_TYPE_ID, VIRTUAL_RECORD_TYPE_ID};
        for ( Opportunity theOpportunity : theOpportunities ) {
            if ( automatedStatusCalculationRecordTypes.contains(theOpportunity.RecordTypeId) ) {
                theOpportunity.StageName = OppStatusCalculatorFactory.getStatusCalculator(theOpportunity.RecordTypeId).calculateNewStatus(theOpportunity);
            }
        }
    }

    /**
     * @description Calculates Opportunity statuses for specified Opportunities Ids
     */
    public static void calculateOpportunitiesStatuses(Set<Id> theOpportunitiesIds) {
        List<Opportunity> oppsForStatusCalculation = [SELECT RecordTypeId, Viewing_Count__c, Event_Count__c, HOTs_Sent__c, HOTs_Signed__c, LA_Sent__c, LA_Signed__c, LT_Case_Completed__c,
                                                             Contracts_Exchanged__c, Contract_Activated__c, Compliance_Check_Complete__c, Virtual_Compliance_Approval_Complete__c,
                                                             Briefing_Statement__c, Deposit_Paid__c, Closed_Lost_Reason__c, Closed_Lost_Comments__c
                                                      FROM Opportunity WHERE Id IN :theOpportunitiesIds];
        calculateOpportunitiesStatuses(oppsForStatusCalculation);
        update oppsForStatusCalculation;
    }

    private static Map<Id, List<Opportunity>> getOpportunitiesMapByRecordTypeId(List<Opportunity> theOpportunities) {
        Map<Id, List<Opportunity>> opportunitiesMap = new Map<Id, List<Opportunity>>();
        for ( Opportunity theOpportunity : theOpportunities ) {
            if ( !opportunitiesMap.containsKey(theOpportunity.RecordTypeId) ) {
                opportunitiesMap.put(theOpportunity.RecordTypeId, new List<Opportunity>());
            }
            opportunitiesMap.get(theOpportunity.RecordTypeId).add(theOpportunity);
        }
        return opportunitiesMap;
    }

    public static Map<String,SBQQ__Quote__c> getPrimaryQuotesByOpportunities (List<Opportunity> opportunities) {
        Map<String,SBQQ__Quote__c> opportunityPrimaryQuoteMap = new Map<String, SBQQ__Quote__c>();

        List<SBQQ__Quote__c> primaryQuotes = [
                SELECT Id, SBQQ__Opportunity2__c, Inventory__r.Name, Inventory__c, Net_Fill_Sq_ft__c,
                        Total_deal_size_Sq_ft__c, Discount_Term_Certain__c, Total_Parking_Spaces__c, Term__c,
                        Term_Certain__c, Rent_per_Sq_Ft_annual__c, Property_Name__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Primary__c = true
                AND SBQQ__Opportunity2__c
                        IN :opportunities];

        for (SBQQ__Quote__c theQuote: primaryQuotes) {
            opportunityPrimaryQuoteMap.put(theQuote.SBQQ__Opportunity2__c, theQuote);
        }

        return opportunityPrimaryQuoteMap;
    }
}