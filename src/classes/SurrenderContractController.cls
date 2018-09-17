public with sharing class SurrenderContractController {
    public static String CONVENTIONAL_RECORD_TYPE_NAME = 'Conventional';
    public static String SERVICED_RECORD_TYPE_NAME = 'Serviced';

    public Contract contract { get; set; }
    public Contract_Surrender__c surrender { get; set; }
    public String errorMessage { get; set; }
    public Boolean isMessageRendered { get; set; }
    public Boolean isServicedRT { get; set; }

    public SurrenderContractController(ApexPages.StandardController stdController) {
        Id contractId = ApexPages.currentPage().getParameters().get('contractId');

        this.surrender = (Contract_Surrender__c) stdController.getRecord();
        this.contract = this.findContractById(contractId);
        this.isMessageRendered = false;

        if (this.contract == null) {
            this.errorMessage = 'Invalid Contract, please try again from Contract detail page';
            this.isMessageRendered = true;
            return;
        }

        Id recordTypeId = this.getRecordTypeId(this.contract);
        if (recordTypeId == null) {
            this.errorMessage = 'It is not possible to create a Surrender Contract for Virtual Sales.';
            this.isMessageRendered = true;
            return;
        }

        this.initSurrender(recordTypeId);
    }

    private void initSurrender(Id recordTypeId) {
        List<Contract_Surrender__c> surrenders = [SELECT Id, Name, RecordTypeId FROM Contract_Surrender__c WHERE Contract__c = :contract.Id];
        if (surrenders.size() > 0) {
            this.surrender = surrenders.get(0);
            this.isServicedRT = this.surrender.RecordTypeId == Schema.SObjectType.Contract_Surrender__c.getRecordTypeInfosByName().get(SERVICED_RECORD_TYPE_NAME).getRecordTypeId();
        }

        if (this.surrender.Id == null) {
            this.surrender.RecordTypeId = recordTypeId;
            this.surrender.Date_Surrender_Triggered__c = Date.today();
            this.surrender.Contract__c = this.contract.Id;
            this.surrender.Name = ('Surrender: ' + this.contract.Name);
            this.surrender.Deposit__c = this.calculateDeposit(this.contract.Id);
            this.surrender.Status__c = 'New';
            this.isServicedRT = this.surrender.RecordTypeId == Schema.SObjectType.Contract_Surrender__c.getRecordTypeInfosByName().get(SERVICED_RECORD_TYPE_NAME).getRecordTypeId();
            this.calculateTerminalDilapidations();
        }
    }

    public void calculateTerminalDilapidations() {
        if (this.isServicedRT) {

            Decimal painting = this.surrender.Painting_Decorating__c != null ? this.surrender.Painting_Decorating__c : 0;
            Decimal cleansing = this.surrender.Carpet_Cleaning__c != null ? this.surrender.Carpet_Cleaning__c : 0;
            Decimal other = this.surrender.Other_Costs__c != null ? this.surrender.Other_Costs__c : 0;
            System.debug(painting + ' + ' + cleansing + ' + ' + other);
            this.surrender.Terminal_Dilapidations__c = painting + cleansing + other;
        }
    }

    public Boolean getSurrenderExists() {
        return this.surrender.Id != null;
    }

    public PageReference cancelSurrender() {
        PageReference thePage = new PageReference('/' + this.contract.Id);
        thePage.setRedirect(true);
        return thePage;
    }

    public PageReference saveSurrender() {
        try {
            insert surrender;
            if (!this.isServicedRT) {
                Case surrenderCase = this.createSurrenderCase(contract, surrender);
                PageReference thePage = new PageReference('/' + surrenderCase.Id);
                thePage.setRedirect(true);
                return thePage;
            }

            return cancelSurrender();
        } catch (DmlException e) {
            this.errorMessage = '';
            for (Integer var = 0; var < e.getNumDml(); var++) {
                this.errorMessage = +e.getDmlMessage(var);
            }
            this.isMessageRendered = true;
        }
        return null;
    }

    private Contract findContractById(Id contractId) {
        List<Contract> contracts = [SELECT Id, Name, AccountId, Pricebook2Id, Pricebook2.Name, SBQQ__Quote__c, SBQQ__Opportunity__c 
                                    FROM Contract WHERE Id = :contractId];
        if (contracts.size() != 0) {
            return contracts.get(0);
        }
        return null;
    }

    private Id getRecordTypeId(Contract contract) {
        Id recordTypeId = null;
        if (contract != null && contract.Pricebook2Id != null) {
            if (contract.Pricebook2.Name.contains(CONVENTIONAL_RECORD_TYPE_NAME)) {
                recordTypeId = Schema.SObjectType.Contract_Surrender__c.getRecordTypeInfosByName().get(CONVENTIONAL_RECORD_TYPE_NAME).getRecordTypeId();
            } else if (contract.Pricebook2.Name.contains(SERVICED_RECORD_TYPE_NAME)) {
                recordTypeId = Schema.SObjectType.Contract_Surrender__c.getRecordTypeInfosByName().get(SERVICED_RECORD_TYPE_NAME).getRecordTypeId();
            }
        }
        return recordTypeId;
    }

    private Decimal calculateDeposit(Id contractId) {
        List<SBQQ__Subscription__c> subscriptions = [
                SELECT Id, SBQQ__UnitCost__c
                FROM SBQQ__Subscription__c
                WHERE SBQQ__Contract__c = :contractId AND SBQQ__Product__r.Is_Deposit__c = TRUE
        ];

        Decimal outputValue = 0;
        for (SBQQ__Subscription__c subscription : subscriptions) {
            outputValue += NumberUtils.convertNullToZero(subscription.SBQQ__UnitCost__c);
        }
        return outputValue;
    }

    private Case createSurrenderCase(Contract contract, Contract_Surrender__c surrender) {
        String recordTypeName = this.isServicedRT ? CaseService.SERVICED_SURRENDER_RECORD_TYPE : CaseService.CONVENTIONAL_SURRENDER_RECORD_TYPE;
        Id recordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(recordTypeName);
        Case surrenderCase =
                new Case(SuppliedName = 'Surrender & ' + contract.Name,
                        AccountId = contract.AccountId,
                        Opportunity__c = contract.SBQQ__Opportunity__c,
                        Quote__c = contract.SBQQ__Quote__c,
                        Contract__c = contract.Id,
                        Contract_Surrender__c = surrender.Id,
                        Proposed_date_of_surrender__c = surrender.Proposed_date_of_surrender__c,
                        Final_Dilapidations__c = surrender.Final_Dilapidations__c,
                        Surrender_Premium__c = surrender.Surrender_Premium__c,
                        Budget_Dilapidations__c = surrender.Budget_Dilapidations__c,
                        Interim_Dilapidations__c = surrender.Interim_Dilapidations__c,
                        Terminal_Dilapidations__c = surrender.Terminal_Dilapidations__c,
                        Break_Penalty_Premium__c = surrender.Break_Penalty_Premium__c,
                        Suite_Restoration__c = surrender.Suite_Restoration__c,
                        Is_the_customer_liable_for_electricity__c = surrender.Is_the_customer_liable_for_electricity__c,
                        Is_the_customer_liable_for_Service_Chrg__c = surrender.Is_the_customer_liable_for_Service_Chrg__c,
                        RecordTypeId = recordTypeId
                );
        insert surrenderCase;
        return surrenderCase;
    }
}