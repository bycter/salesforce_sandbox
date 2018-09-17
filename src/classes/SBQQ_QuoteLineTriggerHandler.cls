public class SBQQ_QuoteLineTriggerHandler extends TriggerHandler {

    private static final String INVENTORY_CAR_PARKING_DEVELOPER_NAME = 'Car_Parking';
    private static final String INVENTORY_ACTUAL_SUITE_DEVELOPER_NAME = 'Actual_Suite';
    private static final String INVENTORY_PROPOSED_SUITE_DEVELOPER_NAME = 'Proposed_Suite';
    private static final String INVENTORY_DESK_DEVELOPER_NAME = 'Desk';

    private static final Map<String, String> PRODUCT_CODE_TO_QUANTA_MAP =
            new Map<String, String>{
                    'OfficeRent' => 'Office',
                    'LabSpace' => 'Lab',
                    'RetailRent' => 'Retail',
                    'Storage' => 'Storage',
                    'BSLF' => 'SerLic',
                    'BSCW' => 'DedLic',
                    'BSDL' => 'DeskLic',
                    'CarParkingLease' => 'CPL',
                    'CarParkLicense' => 'CPL'
            };

    public override void beforeInsert() {
        copyProductFields(Trigger.new);
        setHalfRentAnnualisedAmountWords(Trigger.new);
        populatePropertyFromQuote(Trigger.new);
    }

    public override void beforeUpdate() {
        setHalfRentAnnualisedAmountWords(Trigger.new);
        populatePropertyFromQuote(Trigger.new);
    }

    public override void afterInsert() {
        updateSalesStatusOnRelatedInventories(Trigger.new);
        populateFieldsOnQuote(Trigger.new);
    }

    public override void afterUpdate() {
        updateSalesStatusOnRelatedInventories(Trigger.new);
        populateFieldsOnQuote(Trigger.new);
    }

    private void copyProductFields(List<SBQQ__QuoteLine__c> quoteLines) {
        Set<Id> productIds = SObjectUtils.getIdSetFromObjects(quoteLines, 'SBQQ__Product__c');
        Map<Id, Product2> products = new Map<Id, Product2>([
                SELECT Id, IsConcession__c, ProductCode
                FROM Product2
                WHERE Id IN:productIds
        ]);

        for (SBQQ__QuoteLine__c qLine : quoteLines) {
            if (qLine.SBQQ__Product__c != null) {
                qLine.IsConcession__c = products.get(qLine.SBQQ__Product__c).IsConcession__c;
                qLine.Quanta__c = getQuantaForProduct(products.get(qLine.SBQQ__Product__c));
            }
        }
    }

    private void populateFieldsOnQuote(List<SBQQ__QuoteLine__c> quoteLines) {
        Set<Id> quoteIds = SObjectUtils.getIdSetFromObjects(quoteLines, 'SBQQ__Quote__c');
        List<SBQQ__QuoteLine__c> headLines = SBQQ_QuoteService.getHeadLinesItems(quoteIds);
        Map<Id, List<SBQQ__QuoteLine__c>> headLinesByQuoteId = SObjectUtils.getIdMapFromObjects(headLines, 'SBQQ__Quote__c');
        List<SBQQ_QuoteApprovalHandler.ApprovalInfo> approvalInfos = SBQQ_QuoteApprovalHandler.getApprovalInfos(headLinesByQuoteId);
        Map<Id, SBQQ__Quote__c> quotesForUpdate = new Map<Id, SBQQ__Quote__c>();
        for (SBQQ_QuoteApprovalHandler.ApprovalInfo approvalInfo : approvalInfos) {
            quotesForUpdate.put(approvalInfo.quoteId,new SBQQ__Quote__c(Id = approvalInfo.quoteId, Tolerance_State__c = approvalInfo.toleranceState));
        }

        Map<Id, SBQQ__QuoteLine__c> inventoriesByQuote = getHeadQLIByQuote(headLinesByQuoteId);

        for (Id quoteId: inventoriesByQuote.keySet()) {
            if (quotesForUpdate.containsKey(quoteId)) {
                SBQQ__QuoteLine__c qLine = inventoriesByQuote.get(quoteId);
                quotesForUpdate.get(quoteId).Inventory__c = qLine.Inventory__c;
                quotesForUpdate.get(quoteId).Term__c = qLine.Term__c;
                quotesForUpdate.get(quoteId).Term_Certain__c = qLine.Term_Concessions__c != null ? qLine.Term_Concessions__c : 0;
                quotesForUpdate.get(quoteId).Rent_per_Sq_Ft_annual__c = qLine.Updated_Price_per_sq_ft__c != null ? qLine.Updated_Price_per_sq_ft__c * 12 : 0;
            } else  {
                quotesForUpdate.put(quoteId, new SBQQ__Quote__c(Id = quoteId, Inventory__c = inventoriesByQuote.get(quoteId).Inventory__c));
            }
        }

        if (!quotesForUpdate.isEmpty()) {
            update quotesForUpdate.values();
        }
    }


    private void updateSalesStatusOnRelatedInventories(List<SBQQ__QuoteLine__c> quoteLines) {
        Set<Id> inventoriesIds = new Set<Id>();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.Inventory__c != null) {
                inventoriesIds.add(quoteLine.Inventory__c);
            }
        }
        updateSalesStatusOnInventories([SELECT Id, Sales_Status__c, RecordType.DeveloperName FROM Inventory__c WHERE Id IN :inventoriesIds]);
    }

    private void updateSalesStatusOnInventories(List<Inventory__c> inventories) {
        for (Inventory__c inventory : inventories) {
            if (inventory.RecordType.DeveloperName == INVENTORY_CAR_PARKING_DEVELOPER_NAME
                    || inventory.RecordType.DeveloperName == INVENTORY_DESK_DEVELOPER_NAME) {
                inventory.Sales_Status__c = Constants.INVENTORY_STATUS_RESERVED; //Updates Car Parkings and Desks with Reserved status
            } else if (inventory.RecordType.DeveloperName == INVENTORY_ACTUAL_SUITE_DEVELOPER_NAME
                    || inventory.RecordType.DeveloperName == INVENTORY_PROPOSED_SUITE_DEVELOPER_NAME) {
                inventory.Sales_Status__c = Constants.INVENTORY_STATUS_TERM_OUT; //Updates any others inventories with Instructed status
            }
        }
        update inventories;
    }

    private void setHalfRentAnnualisedAmountWords(List<SBQQ__QuoteLine__c> quoteLines) {
        NumberToWordsConverter.AbstractProcessor processor = new NumberToWordsConverter.BritishPoundsProcessor();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            if (quoteLine.Half_Rent_Annualised_Amount__c != null) {
                quoteLine.Half_Rent_Annualised_text__c = processor.getName(quoteLine.Half_Rent_Annualised_Amount__c);
            }
        }
    }

    private void populatePropertyFromQuote(List<SBQQ__QuoteLine__c> quoteLines) {
        Set<Id> quotesIds = new Set<Id>();
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quotesIds.add(quoteLine.SBQQ__Quote__c);
        }
        Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([select Id, Property__c from SBQQ__Quote__c where Id in :quotesIds]);
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            quoteLine.Property_for_Filter__c = quoteMap.get(quoteLine.SBQQ__Quote__c).Property__c;
        }
    }

    private String getQuantaForProduct(Product2 product) {
        if (product == null || product.ProductCode == null || PRODUCT_CODE_TO_QUANTA_MAP.get(product.ProductCode) == null) {
            return 'None';
        }
        return PRODUCT_CODE_TO_QUANTA_MAP.get(product.ProductCode);
    }

    private Map<Id, SBQQ__QuoteLine__c> getHeadQLIByQuote (Map<Id, List<SBQQ__QuoteLine__c>> headLinesByQuoteId) {
        Map<Id, SBQQ__QuoteLine__c> inventoriesByQuote = new Map<Id, SBQQ__QuoteLine__c>();
        for (Id quoteId: headLinesByQuoteId.keySet()) {
            for (SBQQ__QuoteLine__c qLine: headLinesByQuoteId.get(quoteId)) {
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
                if(inventoriesByQuote.containsKey(quoteId)) {
                    quoteLine = inventoriesByQuote.get(quoteId);
                }

                if (qLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_OFFICE_RENT
                        || qLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_LAB_SPACE
                        || qLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_RETAIL_RENT
                        || qLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_SERVICED) {

                    quoteLine = qLine;

                } else if (qLine.SBQQ__ProductCode__c == ProductService.PRODUCT_CODE_STORAGE
                            && quoteLine.Inventory__c == null) {
                    quoteLine = qLine;
                }
                if (quoteLine.Inventory__c != null) {
                    inventoriesByQuote.put(quoteId,quoteLine);
                }
            }
        }
       return inventoriesByQuote;
    }
}