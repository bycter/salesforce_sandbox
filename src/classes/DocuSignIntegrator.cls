public class DocuSignIntegrator {

    public static final SBQQDS__DocuSignQuoteQuicklySettings__c DOCUSIGN_SETTINGS = SBQQDS__DocuSignQuoteQuicklySettings__c.getOrgDefaults();

    //HTTP SETTINGS
    public static final String HTTP_AUTHENTICATION_HEADER = 'X-DocuSign-Authentication';
    public static final String HTTP_PUT_METHOD = 'PUT';
    public static final String HTTP_POST_METHOD = 'POST';
    public static final String HTTP_CONTENT_TYPE_HEADER = 'Content-Type';
    public static final String HTTP_ACCEPT_HEADER = 'Accept';
    public static final String HTTP_APPLICATION_JSON = 'application/json';

    //ENDPOINS
    private static final String ENDPOINT {get;set;}
    private static final String ACCOUNTS = '/accounts/';
    private static final String ENVELOPES = '/envelopes/';
    private static final String ENVELOPE_ENDPOINT {get;set;}

    //CREDENTIALS
    private static final String ACCOUNT_ID {get;set;}
    private static final String USERNAME {get;set;}
    private static final String PASSWORD {get;set;}
    private static final String INTEGRATOR_KEY {get;set;}

    private static final String DEFAULT_RECIPIENT_ROLE = 'Recipient 1';

    static {
        ENDPOINT = DOCUSIGN_SETTINGS.SBQQDS__Endpoint__c;
        ACCOUNT_ID = DOCUSIGN_SETTINGS.SBQQDS__AccountID__c;
        USERNAME = DOCUSIGN_SETTINGS.Username__c;
        PASSWORD = DOCUSIGN_SETTINGS.Password__c;
        INTEGRATOR_KEY = DOCUSIGN_SETTINGS.Integrator_Key__c;
        ENVELOPE_ENDPOINT = ENDPOINT + ACCOUNTS + ACCOUNT_ID + ENVELOPES;
    }

    @future(callout=true)
    public static void voidEnvelope(String envelopeId) {
        doRequest(ENVELOPE_ENDPOINT + envelopeId, HTTP_PUT_METHOD, generateVoidEnvelopeJson());
    }

    public static String sendEnvelope(String contactName, String contactEmail, String emailSubject, String emailBody, String templateId, String documentName, Id documentId, Id sourceRecordId) {
        String envelopeId = '';
        try {
            HTTPResponse response = doRequest(ENVELOPE_ENDPOINT, HTTP_POST_METHOD, generateCreateEnvelopeJson(contactName, contactEmail, emailSubject, emailBody, templateId, documentName, documentId, sourceRecordId));
            if ( response.getStatusCode() == 200 || response.getStatusCode() == 201 ) {
                String body = response.getBody();
                EnvelopeResponse envResponse = (EnvelopeResponse)JSON.deserialize(body, EnvelopeResponse.class);
                envelopeId = envResponse.envelopeId;
            } else {
                System.debug('*** error: ' + response.getBody());
            }
        } catch (CalloutException ex) {
            System.debug('*** CalloutException: ' + ex.getMessage());
        }
        return envelopeId;
    }

    public static void getEnvelope(String envelopeId) {
        HTTPResponse response = doRequest(ENVELOPE_ENDPOINT + envelopeId, 'GET', null);
        System.debug(response.getBody());
    }

    public static HTTPResponse doRequest(String endpoint, String methodName, String json) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader(HTTP_ACCEPT_HEADER, HTTP_APPLICATION_JSON);
        req.setHeader(HTTP_CONTENT_TYPE_HEADER, HTTP_APPLICATION_JSON);
        req.setHeader(HTTP_AUTHENTICATION_HEADER, generateAuthenticationHeader(USERNAME, PASSWORD, INTEGRATOR_KEY));
        req.setMethod(methodName);
        if ( String.isNotBlank(json) ) {
            req.setbody(json);
        }
        Http http = new Http();
        return http.send(req);
    }

    private static String generateVoidEnvelopeJson() {
        JSONGenerator generator = JSON.createGenerator(true);
        generator.writeStartObject();
        generator.writeStringField('status', 'voided');
        generator.writeStringField('voidedReason', DOCUSIGN_SETTINGS.VoidedReason__c);
        generator.writeEndObject();
        return generator.getAsString();
    }

    private static String generateCreateEnvelopeJson(String contactName, String contactEmail, String emailSubject, String emailBody, String templateId, String documentName, Id documentId, Id sourceRecordId) {
        Envelope theEnvelope = new Envelope(emailSubject, emailBody, templateId);
        Recipient theRecipient = new Recipient(contactName, DEFAULT_RECIPIENT_ROLE, contactEmail);
        theRecipient.recipientId = 1;
        theEnvelope.templateRoles.add(theRecipient);
        if ( sourceRecordId != null ) {
            CustomField mergeFieldConfig = new CustomField();
            mergeFieldConfig.name = sourceRecordId.getSObjectType().getDescribe().getName();
            mergeFieldConfig.value = sourceRecordId;
            Template firstTemplate = new Template(1, new CustomFields(mergeFieldConfig));
            firstTemplate.recipients.signers.add(theRecipient);
            CompositeTemplate theCompositeTemplate = new CompositeTemplate(firstTemplate);
            Template serverTemplate = new Template(1, null);
            serverTemplate.templateId = templateId;
            theCompositeTemplate.serverTemplates.add(serverTemplate);
            theCompositeTemplate.document = new TemplateDocument();
            theCompositeTemplate.document.documentId = 1;
            theCompositeTemplate.document.name = documentName;
            Document ddTemplate = [SELECT Body FROM Document WHERE Id = :documentId];
            theCompositeTemplate.document.documentBase64 = EncodingUtil.base64Encode(ddTemplate.Body);
            theEnvelope.compositeTemplates.add(theCompositeTemplate);
        }
        System.debug('json:' + JSON.serialize(theEnvelope));
        return JSON.serialize(theEnvelope);
    }

    private static String generateAuthenticationHeader(String username, String password, String integratorKey) {
        return String.format('<DocuSignCredentials><Username>{0}</Username><Password>{1}</Password><IntegratorKey>{2}</IntegratorKey></DocuSignCredentials>', new String [] { username, password, integratorKey });
    }

    public class Envelope {
        public String emailSubject { get; set; }
        public String emailBlurb { get; set; }
        public String status { get; set; }
        public String templateId { get; set; }
        public List<Recipient> templateRoles { get; set; }
        public List<CompositeTemplate> compositeTemplates { get; set; }

        public Envelope(String emailSubject, String emailBody, String templateId) {
            this.emailSubject = emailSubject;
            this.emailBlurb = emailBody;
            this.status = 'sent';
            this.templateRoles = new List<Recipient>();
            this.compositeTemplates = new List<CompositeTemplate>();
        }
    }

    public class Recipient {
        public Integer recipientId { get; set; }
        public String email { get; set; }
        public String roleName { get; set; }
        public String name { get; set; }

        public Recipient(String name, String roleName, String email) {
            this.name = name;
            this.roleName = roleName;
            this.email = email;
        }
    }

    public class TemplateRecipient {
        public List<Recipient> signers { get; set; }

        public TemplateRecipient() {
            this.signers = new List<Recipient>();
        }
    }

    public class CompositeTemplate {
        public TemplateDocument document { get; set; }
        public List<Template> inlineTemplates { get; set; }
        public List<Template> serverTemplates { get; set; }

        public CompositeTemplate(Template theTemplate) {
            this.inlineTemplates = new List<Template>();
            this.serverTemplates = new List<Template>();
            this.inlineTemplates.add(theTemplate);
        }
    }

    public class Template {
        public Integer sequence { get; set; }
        public TemplateDocument document { get; set; }
        public CustomFields customFields {  get; set; }
        public TemplateRecipient recipients { get; set; }
        public String templateId { get; set; }

        public Template(Integer sequence, CustomFields theFields) {
            this.sequence = sequence;
            this.customFields = theFields;
            this.recipients = new TemplateRecipient();
        }
    }

    public class TemplateDocument {
        public Integer documentId { get; set; }
        public String name { get; set; }
        public String documentBase64 { get; set; }
    }

    public class CustomFields {
        public List<CustomField> textCustomFields { get; set; }

        public CustomFields(CustomField theField) {
            this.textCustomFields = new List<CustomField>();
            this.textCustomFields.add(theField);
        }
    }

    public class CustomField {
        public String configurationType { get; set; }
        public String name { get; set; }
        public String value { get; set; }
        public Boolean show { get; set; }

        public CustomField() {
            this.configurationType = 'salesforce';
            this.show = true;
        }
    }

    public class EnvelopeResponse {
        public String envelopeId { get; set; }
        public String status { get; set; }
    }
}