public class GenerateIndicativeCostController {
    public static final String EMAIL_BODY = System.Label.Default_email_body;
    public static final Map<String, String> emailTemplatesByPortfolio = new Map<String, String>{
            'Bruntwood' => 'Indicative_Cost_Bruntwood',
            'MSP' => 'Indicative_Cost_MSP',
            'Alderley Park' => 'Indicative_Cost_Alderley_Park'
    };

    private static final String EMPTY_SUITE_ID = '000000000000000AAA';

    public Indicative_Cost__c cost { get; set; }
    public Id propertyId { get; set; }
    public Id suiteId { get; set; }
    public String size { get; set; }
    public String concessionPercent { get; set; }
    public String density { get; set; }
    public String quality { get; set; }

    public GenerateIndicativeCostController(ApexPages.StandardController stdController) {
        cost = (Indicative_Cost__c) stdController.getRecord();
        if (cost == null) {
            cost = new Indicative_Cost__c();
        }
        if (String.isBlank(cost.Email_Body__c)) {
            cost.Email_Body__c = EMAIL_BODY;
        }

        cost.Date__c = Date.today();
        String opportunityId = Apexpages.currentPage().getParameters().get('opportunityId');
        if (!String.isBlank(opportunityId)) {
            populateWithOpportunityParams([SELECT Id, Account.Name FROM Opportunity WHERE Id = :opportunityId]);
        }
    }

    private void populateWithOpportunityParams(Opportunity opportunity) {
        cost.Opportunity__c = opportunity.Id;
        cost.Customer_Name__c = opportunity.Account.Name;
    }

    public PageReference save() {
        PageReference page = null;
        try {
            upsert cost;
            saveAttachmentsOnIndicativeCost();

            page = new PageReference('/' + cost.Opportunity__c);
            page.setRedirect(true);
        } catch (DmlException e) {
            ApexPages.addMessages(e);
        }
        return page;
    }

    public PageReference cancel() {
        PageReference page = new PageReference('/' + cost.Opportunity__c);
        page.setRedirect(true);
        return page;
    }

    private void saveAttachmentsOnIndicativeCost() {
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(getEmailTemplateId(), UserInfo.getUserId(), cost.Id);
        List<Attachment> attachments = new List<Attachment>();
        for (Messaging.EmailFileAttachment emailFileAttachment : mail.getFileAttachments()) {
            attachments.add(new Attachment(
                    Body = emailFileAttachment.getBody(),
                    Name = emailFileAttachment.getFileName(),
                    ParentId = cost.Id)
            );
        }
        upsert attachments;
    }

    private Id getEmailTemplateId() {
        Id templateId;
        String portfolio = [SELECT Portfolio__c FROM Property__c WHERE Id = :cost.Property__c].Portfolio__c;
        templateId = EmailHelper.getEmailTemplateId(emailTemplatesByPortfolio.get(portfolio));
        return templateId;
    }

    public void recalculate() {
        cost.Size_sq_ft__c = getSize(parseInteger(size));
        cost.Concession_Percent__c = getPercent(parseDouble(concessionPercent));
        populateWithPropertyDetails(propertyId);
        if ( suiteId != null && suiteId != EMPTY_SUITE_ID ) {
            populateWithSuiteDetails(suiteId);
        }
        calculateConcession();
        calculateTotalCost();
        calculateDesignCost();
    }

    private void populateWithPropertyDetails(Id propertyId) {
        Property__c property = getPropertyById(propertyId);
        if (property != null) {
            cost.Service_Charge_per_sq_ft__c = property.Service_Charge_per_sq_ft__c;
            cost.Rent_per_sq_ft__c = property.Rent_per_sq_ft__c;
            cost.Insurance_per_sq_ft__c = property.Insurance_Charge_per_sq_ft__c;
        } else {
            cost.Property__c = null;
            cost.Service_Charge_per_sq_ft__c = null;
            cost.Rent_per_sq_ft__c = null;
            cost.Insurance_per_sq_ft__c = null;
        }
    }

    private void populateWithSuiteDetails(Id inventoryId) {
        Inventory__c suite = getInventoryById(inventoryId);
        if (suite != null) {
            cost.Service_Charge_per_sq_ft__c = NumberUtils.convertNullToZero(suite.Service_Charge_per_sq_ft_Annual__c)  != 0 ? suite.Service_Charge_per_sq_ft_Annual__c : cost.Service_Charge_per_sq_ft__c;
            cost.Rent_per_sq_ft__c = NumberUtils.convertNullToZero(suite.Rent_per_sq_ft_Annual__c) != 0 ? suite.Rent_per_sq_ft_Annual__c : cost.Rent_per_sq_ft__c;
            cost.Insurance_per_sq_ft__c = NumberUtils.convertNullToZero(suite.Insurance_Charge_per_sq_ft_Annual__c) != 0 ? suite.Insurance_Charge_per_sq_ft_Annual__c : cost.Insurance_per_sq_ft__c;
            cost.Size_sq_ft__c = suite.Size_sq_ft__c;
        }
    }

    private void calculateConcession() {
        Double percent = cost.Concession_Percent__c != null ? cost.Concession_Percent__c : String.isBlank(concessionPercent) ? 0 : null;
        if (cost.Rent_per_sq_ft__c != null && cost.Size_sq_ft__c != null && percent != null) {
            cost.Concession__c = (cost.Rent_per_sq_ft__c * cost.Size_sq_ft__c / 100) * percent;
        } else {
            cost.Concession__c = null;
        }
    }

    private void calculateTotalCost() {
        if (cost.Size_sq_ft__c != null && cost.Concession__c != null) {
            Double rentCharge = cost.Rent_per_sq_ft__c != null ? cost.Rent_per_sq_ft__c : 0;
            Double serviceCharge = cost.Service_Charge_per_sq_ft__c != null ? cost.Service_Charge_per_sq_ft__c : 0;
            Double insuranceCharge = cost.Insurance_per_sq_ft__c != null ? cost.Insurance_per_sq_ft__c : 0;
            cost.Total_Cost_Per_Annum__c = (rentCharge + serviceCharge + insuranceCharge) * cost.Size_sq_ft__c - cost.Concession__c;
            cost.Total_Cost_Per_Month__c = cost.Total_Cost_Per_Annum__c / 12;
            cost.Total_Cost_Per_Quarter__c = cost.Total_Cost_Per_Annum__c / 4;
        } else {
            cost.Total_Cost_Per_Month__c = null;
            cost.Total_Cost_Per_Quarter__c = null;
            cost.Total_Cost_Per_Annum__c = null;
        }
    }

    private void calculateDesignCost() {
        Property__c property = getPropertyById(propertyId);

        if (String.isNotBlank(density) && String.isNotBlank(quality) && cost.Size_sq_ft__c != null && property != null) {
            Double propertyMultiplier = property.Multiplier__c != null ? property.Multiplier__c : 0;
            String densityMultiplierFieldName = getDensityMultiplierFieldName(density);
            String qualityMultiplierFieldName = getQualityMultiplierFieldName(quality);

            String designCostsSettingsQuery = 'SELECT ' + densityMultiplierFieldName + ', ' + qualityMultiplierFieldName + ', Global_Fit_Out_per_sq_ft__c FROM Design_Costs_Settings__c LIMIT 1';
            List<Design_Costs_Settings__c> designCostsSettings = Database.query(designCostsSettingsQuery);
            if (!designCostsSettings.isEmpty()) {
                cost.Total_Design_Cost__c = designCostsSettings.get(0).Global_Fit_Out_per_sq_ft__c * cost.Size_sq_ft__c * propertyMultiplier * (Double) designCostsSettings.get(0).get(qualityMultiplierFieldName) * (Double) designCostsSettings.get(0).get(densityMultiplierFieldName);
            }
        } else {
            cost.Total_Design_Cost__c = null;
        }
    }

    private Property__c getPropertyById(String propertyId) {
        List<Property__c> properties = [SELECT Id, Multiplier__c, Service_Charge_per_sq_ft__c, Rent_per_sq_ft__c, Insurance_Charge_per_sq_ft__c FROM Property__c WHERE Id = :propertyId];
        if (properties.isEmpty()) {
            return null;
        }
        return properties.get(0);
    }

    private Inventory__c getInventoryById(Id inventoryId) {
        List<Inventory__c> suites = [SELECT Service_Charge_per_sq_ft_Annual__c, Rent_per_sq_ft_Annual__c, Insurance_Charge_per_sq_ft_Annual__c, Size_sq_ft__c FROM Inventory__c WHERE Id = :inventoryId];
        if ( !suites.isEmpty() ) {
            return suites[0];
        }
        return null;
    }

    private String getDensityMultiplierFieldName(String densityValue) {
        return 'Density_' + densityValue + '_Multiplier__c';
    }

    private String getQualityMultiplierFieldName(String qualityValue) {
        return 'Specification_' + qualityValue + '_Multiplier__c';
    }

    private Integer getSize(Integer value) {
        if (value != null && value >= 0) {
            return value;
        }
        return null;
    }

    private Double getPercent(Double value) {
        if (value != null && value <= 100 && value >= 0) {
            return value;
        }
        return null;
    }

    private Integer parseInteger(String numeric) {
        try {
            return Integer.valueOf(numeric);
        } catch (Exception e) {
            return null;
        }
    }

    private Double parseDouble(String numeric) {
        try {
            return Double.valueOf(numeric);
        } catch (Exception e) {
            return null;
        }
    }
}