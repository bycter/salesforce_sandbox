/**
 * Schedulable class for sending emails to customers with request of feedback.
 *
 * @author n.denizhenko
 * @since 4/1/18
 */
global class ScheduledViewingFeedbackEmailSending implements Schedulable {
    public static final Integer MAXIMUM_VIEWINGS_IN_SESSION = 10;
    public static final String VIEWING_CODUCTED_BY_AGENT = 'Agent/Broker';

    public static final String TEMPLATE_ALDERLEY_PARK = 'Viewing_Feedback_Alderley_Park';
    public static final String TEMPLATE_BRUNTWOOD = 'Viewing_Feedback_Bruntwood';
    public static final String TEMPLATE_MSP = 'Viewing_Feedback_MSP';

    public static final String PORTFOLIO_ALDERLEY_PARK = 'ALDERLEY PARK';
    public static final String PORTFOLIO_BRUNTWOOD = 'BRUNTWOOD';
    public static final String PORTFOLIO_MSP = 'MSP';

    public static final Map<String, String> TEMPLATES_MAPPING = new Map<String, String> {
        PORTFOLIO_ALDERLEY_PARK => TEMPLATE_ALDERLEY_PARK,
        PORTFOLIO_BRUNTWOOD => TEMPLATE_BRUNTWOOD,
        PORTFOLIO_MSP => TEMPLATE_MSP
    };

    global void execute(SchedulableContext schedulableContext) {
        sendRequests();
    }

    public void sendRequests() {
        List<Event> viewings = [
                SELECT Id, ActivityDate, WhatId,  WhoId, Customer_Feedback_Requested__c,
                    Viewing_Conducted_by__c, Viewing_Conducted_by_User__c, Portfolio__c, Property__c, Property__r.Name
                FROM Event
                WHERE Customer_Feedback_Requested__c = false
                    AND Status__c = 'Completed'
                    AND ActivityDate <= YESTERDAY
                    AND Dont_send_feedback__c = false
                    AND IsChild = false
                    AND Viewing_Conducted_by__c !=: VIEWING_CODUCTED_BY_AGENT
                ORDER BY CreatedDate
        ];

        Map<String, List<Event>> whoIdPlusDateToEventMap = new Map<String, List<Event>>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadsIds = new Set<Id>();
        //group by whoId and date
        for (Event viewing : viewings) {
            String sObjectName = viewing.WhoId.getSobjectType().getDescribe().getName();
            if (sObjectName == 'Contact') {
                contactIds.add(viewing.WhoId);
            } else if (sObjectName == 'Lead') {
                leadsIds.add(viewing.WhoId);
            }

            //WhoId and date - a key for grouping
            String key = '' + viewing.WhoId + viewing.ActivityDate;
            if (whoIdPlusDateToEventMap.get(key) == null) {
                whoIdPlusDateToEventMap.put(key, new List<Event>());
            }
            whoIdPlusDateToEventMap.get(key).add(viewing);
            viewing.Customer_Feedback_Requested__c = true;
        }

        //create feedback requests
        List<Feedback_Request__c> requests = new List<Feedback_Request__c>();
        Map<String, List<Feedback_Request__c>> requestsMap = new Map<String, List<Feedback_Request__c>>();
        for (String whoIdPlusDateKey : whoIdPlusDateToEventMap.keySet()) {
            //it doesn't matter FROM which viewing in the group we'll pic WhoId and WhatId - they should be the same
            Event firstViewing = whoIdPlusDateToEventMap.get(whoIdPlusDateKey)[0];
            Id whoId = firstViewing.WhoId;

            Feedback_Request__c feedbackRequest = new Feedback_Request__c();
            feedbackRequest.Related_To__c = firstViewing.WhatId;
            feedbackRequest.Viewing_Conducted_by__c = firstViewing.Viewing_Conducted_by__c;
            feedbackRequest.Viewing_Conducted_by_User__c = firstViewing.Viewing_Conducted_by_User__c;

            if (contactIds.contains(whoId)) {
                feedbackRequest.Contact__c = whoId;
            } else if (leadsIds.contains(whoId)) {
                feedbackRequest.Lead__c = whoId;
            }

            addPropertiesToRequest(feedbackRequest, whoIdPlusDateToEventMap.get(whoIdPlusDateKey));

            String portfolio = firstViewing.Portfolio__c.toUpperCase();
            if (!requestsMap.containsKey(portfolio)) {
                requestsMap.put(portfolio, new List<Feedback_Request__c>());
            }
            requestsMap.get(portfolio).add(feedbackRequest);
            requests.add(feedbackRequest);
        }

        insert requests;

        sendEmails(requestsMap);
        update viewings;
    }

    private void sendEmails(Map<String, List<Feedback_Request__c>> requestsMap) {
        OrgWideEmailAddress owa = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress limit 1]; //todo: SELECT right one

        List<String> templateNames = new List<String> {
            TEMPLATE_ALDERLEY_PARK,
            TEMPLATE_BRUNTWOOD,
            TEMPLATE_MSP
        };
        Map<String, Id> templates = new Map<String, Id>();
        for (EmailTemplate tpl :[SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN: templateNames]) {
            templates.put(tpl.DeveloperName, tpl.Id);
        }

        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        for (String key : requestsMap.keySet()) {
            for (Feedback_Request__c request: requestsMap.get(key)) {
                Id templateId = this.getTemplateId(key, templates); 
                allmsg.add(generateEmailMessage(request, templateId, owa.Id));
            }
        }
        Messaging.sendEmail(allmsg, false); //ann or nothing is false - so if it will fail with incorrect email or smth - others will receive their email
    }

    private void addPropertiesToRequest(Feedback_Request__c feedbackRequest, List<Event> viewings) {
        for (Integer i = 1; i <= viewings.size() && i <= MAXIMUM_VIEWINGS_IN_SESSION; i++) {
            Event viewing = viewings.get(i - 1);
            feedbackRequest.put('Property' + i + '__c', viewing.Property__c);
            feedbackRequest.put('Property' + i + '_Name__c', viewing.Property__r.Name);
            feedbackRequest.put('Viewing' + i + '_Id__c', viewing.id);
        }
    }

    private Messaging.SingleEmailMessage generateEmailMessage(Feedback_Request__c request, Id templateId, Id owaId) {
        Id targetId = request.Contact__c != null ? request.Contact__c : request.Lead__c;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetId);
        mail.setSaveAsActivity(false);
        mail.setWhatId(request.Id);
        mail.setOrgWideEmailAddressId(owaId);
        return mail;
    }

    private Id getTemplateId(String key, Map<String, Id> templates) {
        Id templateId = templates.get(TEMPLATE_BRUNTWOOD);
        if (TEMPLATES_MAPPING.containsKey(key)) {
            templateId = templates.get( TEMPLATES_MAPPING.get(key) );
        }
        return templateId;
    }
}