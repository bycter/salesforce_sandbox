/**
 * @description General class for SpringCM buttons
 */
public with sharing virtual class SpringCMBtnController {

    private static final String URL_ENCODING = 'UTF-8';

    public static final String SPRING_CM_DEFAULT_ENDPOINT = 'na11.springcm.com';
    public static final String SPRING_CM_DOCUMENT_CREATOR = '/atlas/doclauncher/eos/Create Document';
    public static final String SPRING_CM_CONTRACT_CREATOR = '/atlas/doclauncher/eos/Create Lease';
    public static final String SPRING_CM_PARAMETERS = '?aid={0}&eos[0].Id={1}&eos[0].System=Salesforce&eos[0].Type=Case&eos[0].Name={2}&eos[0].ScmPath=/Salesforce/Accounts/{3}/Opportunities/{4}/Quotes/{5}/Cases';

    protected String springCMAction { get; set; }
    protected SpringCMEos__Environment__c springCMSettings { get; set; }
    protected Case theCase { get; set; }

    public SpringCMBtnController(ApexPages.StandardController stdController) {
        springCMSettings = !SpringCMEos__Environment__c.getAll().isEmpty() ? SpringCMEos__Environment__c.getAll().values()[0] : new SpringCMEos__Environment__c();
        if ( !Test.isRunningTest() ) {
            stdController.addFields(new List<String>{'CaseNumber', 'Account.Name', 'Opportunity__r.Name', 'Quote__r.Name'});
        }
        theCase = (Case)stdController.getRecord();
    }

    public PageReference redirectToSpringCM() {
        String endpoint = 'https://' + (String.isNotBlank(springCMSettings.SpringCMEos__Env_Prefix__c) ? springCMSettings.SpringCMEos__Env_Prefix__c : SPRING_CM_DEFAULT_ENDPOINT) + springCMAction;
        String formattedParameters = String.format(SPRING_CM_PARAMETERS, new List<String>{springCMSettings.SpringCMEos__SpringCM_Account_ID__c, theCase.Id, theCase.CaseNumber,
                                                                                          EncodingUtil.urlEncode(theCase.Account.Name, URL_ENCODING), EncodingUtil.urlEncode(theCase.Opportunity__r.Name, URL_ENCODING),
                                                                                          EncodingUtil.urlEncode(theCase.Quote__r.Name, URL_ENCODING)});
        String fullUrl = endpoint + formattedParameters;
        PageReference pageRef = new PageReference(endpoint + formattedParameters);
        return pageRef;
    }
}