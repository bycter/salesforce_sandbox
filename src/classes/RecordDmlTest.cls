public class RecordDmlTest {
    private static Account generatedAccount;


    public static Event createEvent() {
        Event e = new Event(Subject = getRandomString(), DurationInMinutes = randomWithLimit(100), ActivityDateTime = Datetime.now(), Viewing_Conducted_by_User__c = createUser().Id, RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Event').getRecordTypeId());
        insert e;
        return e;
    }

    public static Case createCaseRelatedToInventory() {
        return createCaseRelatedToInventoryWithRecordType('Lease_Transaction');
    }

    public static Case createCaseRelatedToInventoryWithRecordType(String recordTypeDeveloperName) {
        Property__c property = createProperty();
        List<Product2> prodList = createProducts();

        Product2 product = [SELECT Id, Name, Family, ProductCode FROM Product2 WHERE Family = 'Suite' and ProductCode = 'OfficeRent' LIMIT 1];

        Inventory__c inventory = createActualSuiteInventory(product, property);
        Case newCase = new Case(Subject = 'Test Case', Inventory__c = inventory.Id, Property__c = property.Id,
            RecordTypeId = RecordTypeHelper.getCaseRtIdByDeveloperName(recordTypeDeveloperName));
        insert newCase;
        return newCase;
    }

    public static List<Event> createViewingEvents(Integer num, Id whoId, Id whatId, Id propertyId) {
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < num; i++) {
            events.add(new Event(
                    Subject = getRandomString(),
                    WhatId = whatId,
                    WhoId = whoId,
                    Property__c = propertyId,
                    Status__c = 'Completed',
                    Dont_send_feedback__c = true,
                    DurationInMinutes = randomWithLimit(100),
                    ActivityDateTime = Datetime.now().addDays(-2),
                    Viewing_Conducted_by_User__c = createUser().Id,
                    RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Viewing').getRecordTypeId()
            ));
        }
        insert events;
        for (Event e : events) {
            e.Dont_send_feedback__c = false; //workaround for validation
        }
        update events;
        return events;
    }

    public static Event createViewingEvent(Id whoId, Id whatId, Id propertyId) {
        Event e = new Event(
                Subject = getRandomString(),
                WhatId = whatId,
                WhoId = whoId,
                Property__c = propertyId,
                Status__c = 'Completed',
                Dont_send_feedback__c = true,
                DurationInMinutes = randomWithLimit(100),
                ActivityDateTime = Datetime.now().addDays(-2),
                Viewing_Conducted_by_User__c = createUser().Id,
                RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByName().get('Viewing').getRecordTypeId()
        );
        insert e;
        e.Dont_send_feedback__c = false; //workaround for validation
        update e;
        return e;
    }

    public static EventRelation createEventRelation() {
        Id relationId = randomWithLimit(100) < 50 ? createContact().Id : createUser().Id;
        EventRelation relation = new EventRelation(EventId = createEvent().Id, RelationId = relationId, IsInvitee = true);
        insert relation;
        return relation;
    }

    public static Contact createContact() {
        Contact c = new Contact(FirstName = getRandomString(), LastName = getRandomString(), AccountId = createAccount().Id, Email = randomWithLimit(1000000) + '@test31.com');
        insert c;
        return c;
    }

    public static Contract createContract(SBQQ__Quote__c quote, Property__c property) {

        Contract contract =  new Contract(Property__c = property.Id, SBQQ__Quote__c = quote.Id, AccountId = quote.SBQQ__Account__c, CurrencyIsoCode = 'GBP',
                Status = 'Draft', StartDate = System.today() + 10, ContractTerm = 10, contract_term__c = 10);
        insert contract;
        return contract;
    }

    public static Contact createContact(Id accountId, String contactType) {
        Contact testContact = new Contact(FirstName = getRandomString(), LastName = getRandomString(), AccountId = accountId, Email = randomWithLimit(1000000) + '@test31.com', Contact_Type__c = contactType);
        return testContact;
    }

    public static Contract createContract() {
        Account account = createAccount();
        Property__c property = createProperty();
        Pricebook2 priceBook = createPricebook('Serviced');
        fferpcore__Company__c legalEntity = new fferpcore__Company__c();
        insert legalEntity;
        Customer_Confidential_Documentation__c ddMandate = new Customer_Confidential_Documentation__c();
        insert ddMandate;
        Contract contract = new Contract(
                Name = 'TestName',
                AccountId = account.Id,
                Property__c = property.Id,
                Pricebook2Id = priceBook.Id,
                Legal_Entity__c = legalEntity.Id,
                DD_Mandate__c = ddMandate.Id,
                First_Bill_Date__c = System.today(),
                StartDate = System.today(),
                ContractTerm=10,
                Contract_Term__c = 10,
                EndDate = System.today().addDays(10)
        );
        insert contract;
        return contract;
    }

    public static Account createAccount() {
        return createAccount(true);
    }

    public static Account createAccount(Boolean saveToDb) {
        if (generatedAccount == null) {
            generatedAccount = new Account(Name = getRandomString(), BillingCity = getRandomString(), BillingCountry = getRandomString(), BillingStreet = getRandomString(), BillingPostalCode = String.valueOf(randomWithLimit(10000)));
            if (saveToDb) {
                insert generatedAccount;
            }
        }
        return generatedAccount;
    }

    public static Account createQuniqueAccount(Boolean saveToDb) {
        Account testAccount = new Account(Name = getRandomString(), BillingCity = getRandomString(), BillingCountry = getRandomString(), BillingStreet = getRandomString(), BillingPostalCode = String.valueOf(randomWithLimit(10000)));
        if (saveToDb) {
            insert testAccount;
        }
        return testAccount;
    }


    public static User createUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        String username = getRandomString() + dateString + randomInt;
        User u = new User(Alias = 'standt', Email = username + '@test31.com', EmailEncodingKey = 'UTF-8', LastName = 'Test' + getRandomString(), LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = username + '@test31.com');
        insert u;
        return u;
    }


    public static SBQQ__Quote__c createCPQQuote() {
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Account__c = createAccount().Id, SBQQ__PrimaryContact__c = createContact().Id);
        insert q;
        return q;
    }


    public static SBQQDS__DocuSignQuoteQuicklySettings__c createDocusignSettings() {
        SBQQDS__DocuSignQuoteQuicklySettings__c docusignSettings = new SBQQDS__DocuSignQuoteQuicklySettings__c(
                SBQQDS__AccountID__c = 'testAccountID',
                SBQQDS__BatchSize__c = 5,
                SBQQDS__Endpoint__c = 'https://demo.docusign.net/',
                Integrator_Key__c = 'IntegratorKeyID',
                Password__c = 'Password',
                Username__c = 'Username',
                VoidedReason__c = 'Voided reason text');
        insert docusignSettings;
        return docusignSettings;
    }

    public static c2g__codaGeneralLedgerAccount__c createGeneralLedgerAccount() {
        c2g__codaGeneralLedgerAccount__c generalAccount = new c2g__codaGeneralLedgerAccount__c(
                Name = 'Test',
                c2g__ReportingCode__c = '4230812am',
                c2g__Type__c = 'Balance Sheet'
        );
        insert generalAccount;
        return generalAccount;
    }

    public static c2g__codaTaxCode__c createTaxCode(String taxCodeName) {
        c2g__codaTaxCode__c taxCode = new c2g__codaTaxCode__c(
                Name = taxCodeName,
                c2g__ExternalId__c = taxCodeName,
                c2g__GeneralLedgerAccount__c = createGeneralLedgerAccount().Id
        );
        insert taxCode;
        return taxCode;
    }

    public static c2g__codaCompany__c createCompany(String companyName) {
        c2g__codaCompany__c company = new c2g__codaCompany__c(
                Name = companyName
        );
        insert company;
        return company;
    }

    public static Ad_hoc_Revenue__c createAdHocRevenue(Account acc, c2g__codaTaxCode__c taxCode, Property__c prop, c2g__codaCompany__c company, Product2 product) {
        return new Ad_hoc_Revenue__c(
                Legal_Entity__c = company.Name,
                Customer_Account__c = acc.Id,
                Customer_Reference__c = 'Customer_Reference',
                Currency__c = 'GBP',
                Property__c = prop.Id,
                Due_Date__c = Date.today(),
                Invoice_Date__c = Date.today(),
                Invoice_Description__c = 'Invoice Description',
                Period__c = 'Period',
                Product__c = product.Id,
                Quantity__c = 1.0,
                Unit_Price__c = 1,
                Tax_Code__c = taxCode.Name,
                Document_Type__c = 'Invoice',
                From_Date__c = Date.today(),
                To_Date__c = Date.today()
        );
    }

    public static List<Ad_hoc_Revenue__c> createAdHocRevenues(Account acc, c2g__codaTaxCode__c taxCode, Property__c prop, c2g__codaCompany__c company, Product2 product) {
        Integer count = 2;
        List<Ad_hoc_Revenue__c> adHocRevenues = new List<Ad_hoc_Revenue__c>();
        for (Integer i = 0; i < count; i++) {
            adHocRevenues.add(createAdHocRevenue(acc, taxCode, prop, company, product));
        }
        return adHocRevenues;
    }

    public static List<Event> createEvents() {
        Integer count = randomWithLimit(3);
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < count; i++) {
            events.add(createEvent());
        }
        return events;
    }


    public static List<EventRelation> createEventRelations() {
        Integer count = randomWithLimit(3);
        List<EventRelation> relations = new List<EventRelation>();
        for (Integer i = 0; i < count; i++) {
            relations.add(createEventRelation());
        }
        return relations;
    }


    public static List<EmailTemplate> createEmailTemplates() {
        List<EmailTemplate> templates = new List<EmailTemplate>();
        templates.add(new EmailTemplate(Name = Label.ViewingUpdatedContactTemplate, DeveloperName = Label.ViewingUpdatedContactTemplate, TemplateType = 'visualforce', Markup = getTemplateMarkup('Contact', 'Event'), FolderId = UserInfo.getUserId()));
        templates.add(new EmailTemplate(Name = Label.ViewingUpdatedUserTemplate, DeveloperName = Label.ViewingUpdatedUserTemplate, TemplateType = 'visualforce', Markup = getTemplateMarkup('User', 'Event'), FolderId = UserInfo.getUserId()));
        templates.add(new EmailTemplate(Name = Label.ViewingCreatedContactTemplate, DeveloperName = Label.ViewingCreatedContactTemplate, TemplateType = 'visualforce', Markup = getTemplateMarkup('Contact', 'Event'), FolderId = UserInfo.getUserId()));
        templates.add(new EmailTemplate(Name = Label.ViewingCreatedUserTemplate, DeveloperName = Label.ViewingCreatedUserTemplate, TemplateType = 'visualforce', Markup = getTemplateMarkup('User', 'Event'), FolderId = UserInfo.getUserId()));
        insert templates;
        return templates;
    }

    private static String getTemplateMarkup(String recipientType, String relatedToType) {
        return '<messaging:emailTemplate subject = "Test" recipientType= "' + recipientType + '" relatedToType="' + relatedToType + '"><messaging:htmlEmailBody ></messaging:htmlEmailBody></messaging:emailTemplate>';
    }

    private static Integer randomWithLimit(Integer upperLimit) {
        Integer rand = Math.round(Math.random() * 1000);
        return Math.mod(rand, upperLimit);
    }

    public static List<Product2> createProducts() {
        return createProducts(Test.getStandardPricebookId());
    }

    public static List<Product2> createProducts(Id pricebookId) {
        Product2[] pList = new List<Product2>();
        pList.add(new Product2(Name = 'Car Parking License', Productcode = 'CarParkLicense', Family = 'Car space', HOT_TYPE__C = 'CarParkLicense', IsActive = true));
        pList.add(new Product2(Name = 'Contribution to Customer\'s Legal Fees', Productcode = 'CustomerLegalFees', Family = '?', HOT_TYPE__C = 'CustomerLegalFees', IsActive = true));
        pList.add(new Product2(Name = 'Estate Charge', Productcode = 'EstateCharge', Family = '', HOT_TYPE__C = 'EstateCharge', IsActive = true));
        pList.add(new Product2(Name = 'Deposit (Retain)', Productcode = 'DepositRetain', Family = '?', HOT_TYPE__C = 'Deposit', IsActive = true));
        pList.add(new Product2(Name = 'Customer Break Option', Productcode = 'CustomerBreakOption', Family = 'Date', HOT_TYPE__C = 'CustomerBreakOption', IsActive = true));
        pList.add(new Product2(Name = 'Rent Review', Productcode = 'RentReview', Family = 'Days', HOT_TYPE__C = 'RentReview', IsActive = true));
        pList.add(new Product2(Name = 'Service Charge Cap', Productcode = 'ServiceChargeCap', Family = '?', HOT_TYPE__C = 'ServiceChargeCap', IsActive = true));
        pList.add(new Product2(Name = 'Rent Free', Productcode = 'RentFree', Family = 'Days', HOT_TYPE__C = 'RentFree', IsActive = true, IsConcession__c = true));
        pList.add(new Product2(Name = 'Half Rent', Productcode = 'HalfRent', Family = 'Days', HOT_TYPE__C = 'HalfRent', IsActive = true, IsConcession__c = true));
        pList.add(new Product2(Name = 'Stepped Rent', Productcode = 'SteppedRent', Family = 'Days', HOT_TYPE__C = 'SteppedRent', IsActive = true, IsConcession__c = true));
        pList.add(new Product2(Name = 'Building Insurance', Productcode = 'BuildingInsurance', Family = 'sqft', HOT_TYPE__C = 'BuildingInsurance', IsActive = true));
        pList.add(new Product2(Name = 'Ground Rent', Productcode = 'GroundRent', Family = 'suite', HOT_TYPE__C = 'GroundRent', IsActive = true));
        pList.add(new Product2(Name = 'Service Charge', Productcode = 'ServiceCharge', Family = '?', HOT_TYPE__C = 'ServiceCharge', IsActive = true));
        pList.add(new Product2(Name = 'Car Parking Lease', Productcode = 'CarParkingLease', Family = 'Car space', HOT_TYPE__C = 'CarParkingLease', IsActive = true));
        pList.add(new Product2(Name = 'CAT B Fit-Out by Supplier', Productcode = 'FitOut123', Family = '?', HOT_TYPE__C = 'FitOutSupplier', IsActive = true));
        pList.add(new Product2(Name = 'Office Rent', Productcode = 'OfficeRent', Family = 'suite', HOT_TYPE__C = 'Suite', IsActive = true));
        pList.add(new Product2(Name = 'Office Rent', Productcode = 'RetailRent', Family = 'suite', HOT_TYPE__C = 'Suite', IsActive = true));
        pList.add(new Product2(Name = 'Office Rent', Productcode = 'LabSpace', Family = 'suite', HOT_TYPE__C = 'Suite', IsActive = true));
        pList.add(new Product2(Name = 'Supplier Break Option', Productcode = 'SupplierBreakOption', Family = 'Date', HOT_TYPE__C = 'SupplierBreakOption', IsActive = true));
        pList.add(new Product2(Name = 'CAT A Refurbishment by Supplier', Productcode = 'RefurbishmentSupplier', Family = 'None', HOT_TYPE__C = 'RefurbishmentSupplier', IsActive = true));
        pList.add(new Product2(Name = 'CAT A Refurbishment by Customer', Productcode = 'RefurbishmentCustomer', Family = 'None', HOT_TYPE__C = 'RefurbishmentCustomer', IsActive = true));
        pList.add(new Product2(Name = 'CAT B Fit-Out by Customer', Productcode = 'FitOutCustomer', Family = '?', HOT_TYPE__C = 'FitOutCustomer', IsActive = true));
        pList.add(new Product2(Name = 'Guarantor', Productcode = 'Guarantor', Family = 'None', HOT_TYPE__C = 'Guarantor', IsActive = true));
        pList.add(new Product2(Name = 'Contracted Out', Productcode = 'ContractedOut', Family = 'None', HOT_TYPE__C = 'ContractedOut', IsActive = true));
        pList.add(new Product2(Name = 'Schedule of Condition', Productcode = 'ScheduleCondition', Family = 'None', HOT_TYPE__C = 'ScheduleCondition', IsActive = true));
        pList.add(new Product2(Name = 'Air Conditioning', Productcode = 'AirConditioning', Family = 'None', HOT_TYPE__C = 'AirConditioning', IsActive = true));
        pList.add(new Product2(Name = 'Pre-Emption Agreement', Productcode = 'PreEmptionAgreement', Family = 'None', HOT_TYPE__C = 'PreEmptionAgreement', IsActive = true));
        pList.add(new Product2(Name = 'Electricity', Productcode = 'Electricity', Family = 'None', HOT_TYPE__C = 'Electricity', IsActive = true));
        pList.add(new Product2(Name = 'City Labs Car Park Levee', Productcode = 'CityLabsCarParkLevee', Family = 'Car space', HOT_TYPE__C = 'CarParkLevee', IsActive = true));

        pList.add(new Product2(Name = 'Supplier 24 Hour Notice', Productcode = 'BS24', Family = '', HOT_TYPE__C = 'Supplier24Notice', IsActive = true));
        pList.add(new Product2(Name = 'Additional Seats', Productcode = 'BSAS', Family = '', HOT_TYPE__C = 'AdditionalSeats', IsActive = true));
        pList.add(new Product2(Name = 'Customer Break', Productcode = 'BSCB', Family = '', HOT_TYPE__C = 'CustomerBreakOption', IsActive = true));
        pList.add(new Product2(Name = 'Dedicated Leased Line Internet', Productcode = 'BSDM20', Family = '', HOT_TYPE__C = 'DedicatedInternet', IsActive = true));
        pList.add(new Product2(Name = 'Dilapidations', Productcode = 'BSDL', Family = '', HOT_TYPE__C = 'Dilapidations', IsActive = true));
        pList.add(new Product2(Name = 'Deposit', Productcode = 'BSDP', Family = '', HOT_TYPE__C = 'Deposit', IsActive = true));
        pList.add(new Product2(Name = 'Handsets', Productcode = 'BSHD', Family = '', HOT_TYPE__C = 'Handsets', IsActive = true));
        pList.add(new Product2(Name = 'Internet Corkage Fee', Productcode = 'BSIC', Family = '', HOT_TYPE__C = 'InternetCorkageFee', IsActive = true));
        pList.add(new Product2(Name = 'Inclusive Contended Internet', Productcode = 'BSII', Family = '', HOT_TYPE__C = 'InclusiveInternet', IsActive = true));
        pList.add(new Product2(Name = 'Supplier Injury Liability', Productcode = 'BSIL', Family = '', HOT_TYPE__C = 'SupplierInjuryLiability', IsActive = true));
        pList.add(new Product2(Name = 'Serviced Licence Fee', Productcode = 'BSLF', Family = 'suite', HOT_TYPE__C = 'Suite', IsActive = true));
        pList.add(new Product2(Name = 'Meeting Room Usage', Productcode = 'BSNM', Family = '', HOT_TYPE__C = 'MeetingRoom', IsActive = true));
        pList.add(new Product2(Name = 'Company Name on Signboard', Productcode = 'BSNS', Family = '', HOT_TYPE__C = 'CompanyName', IsActive = true));
        pList.add(new Product2(Name = 'Use of Building as Registered Address', Productcode = 'BSRA', Family = '', HOT_TYPE__C = 'BuildingRegisteredAddress', IsActive = true));
        pList.add(new Product2(Name = 'Customer Repairs Liability', Productcode = 'BSRL', Family = '', HOT_TYPE__C = 'CustomerRepairsLiability', IsActive = true));
        pList.add(new Product2(Name = 'Remove Supplier Liability Indemnity', Productcode = 'BSRS', Family = '', HOT_TYPE__C = 'RemoveSupplierLiabilityIndemnity', IsActive = true));
        pList.add(new Product2(Name = 'Telephone Handsets and Line Rental', Productcode = 'BSTR', Family = '', HOT_TYPE__C = 'LineRental', IsActive = true));
        pList.add(new Product2(Name = 'Voicemail Facility and Fax Line', Productcode = 'BSVF', Family = '', HOT_TYPE__C = 'Voicemail Facility and Fax Line', IsActive = true));
        pList.add(new Product2(Name = 'Wear and Tear', Productcode = 'BSWT', Family = '', HOT_TYPE__C = 'WearAndTear', IsActive = true));

        pList.add(new Product2(Name = 'UVirtual lic fee', Productcode = 'BVLF', Family = 'suite'));
        pList.add(new Product2(Name = 'virt1', Productcode = 'BVRA', Family = ''));
        pList.add(new Product2(Name = 'virt2', Productcode = 'BVCN', Family = ''));
        pList.add(new Product2(Name = 'virt3', Productcode = 'BVCH', Family = ''));
        pList.add(new Product2(Name = 'virt4', Productcode = 'BVCF', Family = ''));
        insert pList;

        PricebookEntry[] pbe = new List<PricebookEntry>();
        PricebookEntry[] pbeStd = new List<PricebookEntry>();
        for (Product2 p : pList) {
            pbeStd.add(new PricebookEntry(
                    Product2Id = p.Id,
                    Pricebook2Id = Test.getStandardPricebookId(),
                    CurrencyIsoCode = 'GBP',
                    IsActive = true,
                    UnitPrice = 10
            ));
            if (pricebookId != Test.getStandardPricebookId()) {
                pbe.add(new PricebookEntry(
                        Product2Id = p.Id,
                        Pricebook2Id = pricebookId,
                        CurrencyIsoCode = 'GBP',
                        IsActive = true,
                        UnitPrice = 10,
                        UseStandardPrice = false
                ));
            }
        }
        insert pbeStd;
        insert pbe;
        return pList;
    }

    public static Pricebook2 createPricebook(String name) {
        Pricebook2 priceB = new Pricebook2(Name = name);
        insert priceB;
        return priceB;
    }

    public static Property__c createProperty() {
        Document directDebitForm = new Document();
        Document[] dDFormList = [SELECT ID, DeveloperName FROM Document WHERE DeveloperName = 'Direct_Debit_1' LIMIT 1];
        if (dDFormList.size() == 0) {
            directDebitForm = new Document(
                    Body = Blob.valueOf('Test Document'),
                    ContentType = 'application/pdf',
                    DeveloperName = 'Direct_Debit_1',
                    IsPublic = true,
                    Name = 'Direct Debit',
                    FolderId = [SELECT Id FROM Folder WHERE DeveloperName = 'Quote_Documents'].id);
            insert directDebitForm;
        } else {
            directDebitForm = dDFormList[0];
        }

        c2g__codaCompany__c ffCompany = new c2g__codaCompany__c(
                Direct_Debit_Form_Developer_Name__c = directDebitForm.DeveloperName);
        insert ffCompany;

        User user = createUser();
        User servicedSpaceCoordinator = createUser();

        Property__c property = new Property__c(Name = '111 Piccadilly', Region__c = 'Liverpool',
                Active__c = true, Street__c = getRandomString(), Property_Manager__c = user.Id,
                Serviced_Space_Coordinator__c = servicedSpaceCoordinator.Id, Company__c = ffCompany.Id);
        insert property;
        return property;

    }

    public static Inventory__c createActualSuiteInventory(Product2 prod, Property__c prop) {
        return createInventory(prod, prop, 'Actual_Suite', 'Actual');
    }

    public static Inventory__c createActualCarParkingInventory(Product2 prod, Property__c prop) {
        return createInventory(prod, prop, 'Car_Parking', 'Actual');
    }

    public static Inventory__c createProposedSuiteInventory(Product2 prod, Property__c prop) {
        return createInventory(prod, prop, 'Proposed_Suite', 'Proposed');
    }

    public static Inventory__c createInventory(Product2 prod, Property__c prop, String recordtypeDeveloperName, String status) {
        Inventory__c inventory = createInventoryNoInsert(prod, prop, recordtypeDeveloperName, status);
        insert inventory;
        return inventory;
    }

    public static Inventory__c createInventoryNoInsert(Product2 prod, Property__c prop, String recordtypeDeveloperName, String status) {
        Inventory__c inventory = new Inventory__c(Name = getRandomString(),
                Sales_Status__c = 'Available', Suite_Status__c = status, Size_sq_ft__c = 1000, Rent_per_sq_ft__c = 1,
                RecordTypeDeveloperName__c=recordtypeDeveloperName,
                Service_Charge_per_sq_ft__c = 1, Estate_Charge_per_sq_ft__c = 1, Insurance_Charge_per_sq_ft__c = 1, Ground_Rent_Charge_per__c = 1,
                Product__c = prod.Id, Property__c = prop.Id, Workstations__c = 1, Rent_per_workstation__c = 1);
        return inventory;
    }

    public static Lead createLead() {
        Lead lead = new Lead(
                LastName = getRandomString(),
                Company = getRandomString(),
                Channel__c = 'Email',
                Email = 'a@a.com');
        insert lead;
        return lead;
    }

    public static Opportunity createOpportunity(String RecordTypeName) {
        Id rtIdConv = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(RecordTypeName).getRecordTypeId();
        Opportunity op = new Opportunity(Name = getRandomString(), AccountId = createAccount().Id, RecordTypeId = rtIdConv, CloseDate = Date.today(),
                Type = 'New Customer', StageName = 'Qualified', Region__c = 'Liverpool', LeadSource = 'Event', Channel__c = 'Email');
        insert op;
        return op;
    }

    public static SBQQ__Quote__c createQuote(Property__c prop, Opportunity opp, String RecordTypeName) {
        Id rtIdConvQuote = Schema.SObjectType.SBQQ__Quote__c.getRecordTypeInfosByName().get(RecordTypeName).getRecordTypeId();
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Account__c = createAccount().Id, SBQQ__PrimaryContact__c = createContact().Id, RecordTypeId = rtIdConvQuote,
                SBQQ__Opportunity2__c = opp.Id, Property__c = prop.Id, SBQQ__PriceBook__c = opp.Pricebook2.id, SBQQ__Status__c = 'Draft', SBQQ__Type__c = 'New Deal');
        insert q;
        return q;
    }

    public static List<SBQQ__QuoteLine__c> createQuoteLine(SBQQ__Quote__c q, List<Product2> prodList) {
        SBQQ.TriggerControl.disable();
        List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
        Inventory__c inv = [SELECT Id FROM Inventory__c LIMIT 1];
        for (Product2 prod : prodList) {
            if (prod.Family == 'suite') {
                SBQQ__QuoteLine__c suite = new SBQQ__QuoteLine__c(
                        Cap_Expiry_Month__c = 45,
                        SBQQ__Quote__c = q.Id,
                        SBQQ__Product__c = prod.Id,
                        List_Price__c = 1,
                        SBQQ__SubscriptionTerm__c = 1,
                        SBQQ__Discount__c = 0.01,
                        Monthly_Average_Without_Discount__c = 100,
                        Term__c = 30,
                        Start_Date__c = Date.today().addMonths(1),
                        Monthly_Average__c = 200.0,
                        Break_Date__c = 20.0,
                        SBQQ__Bundle__c = true,
                        SBQQ__Quantity__c = 1,
                        Inventory__c = inv.Id,
                        Suite_Inventory__c = inv.Id
                );
                qliList.add(suite);
            }
        }
        insert qliList;

        List<SBQQ__QuoteLine__c> trivialLines = new List<SBQQ__QuoteLine__c>();
        for (Product2 prod : prodList) {
            if (prod.Family != 'suite') {
                SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                        Cap_Expiry_Month__c = 45,
                        SBQQ__Quote__c = q.Id,
                        SBQQ__Product__c = prod.Id,
                        List_Price__c = 1,
                        SBQQ__SubscriptionTerm__c = 1,
                        SBQQ__Discount__c = 0.01,
                        Term__c = 30,
                        Start_Term__c = 2,
                        Discount_Percent__c = 2,
                        Monthly_Average__c = 200.0,
                        Break_Date__c = 20.0,
                        Rent_Step_To__c = 3,
                        SBQQ__Quantity__c = 1,
                        Monthly_Cost__c = 1,
                        Suite_Inventory__c = inv.Id,
                        SBQQ__RequiredBy__c = qliList.size() > 0 ? qliList.get(0).Id : null
                );
                trivialLines.add(quoteLine);
            }
        }
        insert trivialLines;
        qliList.addAll(trivialLines);
        return qliList;
    }

    public static SBQQ__Quote__c generateConventionalQuoteWithLines(String headlineProductCode) {
        Map<String, Product2> mapProdByType = new Map<String, Product2>();
        List<SBQQ__QuoteLine__c> qLines = new List<SBQQ__QuoteLine__c>();
        List<Product2> prodToQLI = new List<Product2>();
        SBQQ__Quote__c quote = preGenerateQuote('Conventional');

        mapProdByType = mapProdByType();

        prodToQLI.add(mapProdByType.get(headlineProductCode));
        prodToQLI.add(mapProdByType.get('ContractedOut'));
        prodToQLI.add(mapProdByType.get('ScheduleCondition'));
        prodToQLI.add(mapProdByType.get('AirConditioning'));
        prodToQLI.add(mapProdByType.get('DepositRetain'));
        prodToQLI.add(mapProdByType.get('RentReview'));
        prodToQLI.add(mapProdByType.get('BuildingInsurance'));
        prodToQLI.add(mapProdByType.get('Guarantor'));
        prodToQLI.add(mapProdByType.get('ServiceCharge'));
        prodToQLI.add(mapProdByType.get('FitOutCustomer'));
        prodToQLI.add(mapProdByType.get('CustomerBreakOption'));
        prodToQLI.add(mapProdByType.get('CustomerBreakOption'));
        prodToQLI.add(mapProdByType.get('CustomerBreakOption'));

        qLines = createQuoteLine(quote, prodToQLI);

        return quote;
    }

    public static SBQQ__Quote__c generateConventionalQuoteWithServiceChargeCapLines() {
        SBQQ__Quote__c quote = preGenerateQuote('Conventional');
        Map<String, Product2> mapProdByType = mapProdByType();

        List<Product2> prodToQLI = new List<Product2>();
        prodToQLI.add(mapProdByType.get('OfficeRent'));
        prodToQLI.add(mapProdByType.get('ContractedOut'));
        prodToQLI.add(mapProdByType.get('ScheduleCondition'));
        prodToQLI.add(mapProdByType.get('AirConditioning'));
        prodToQLI.add(mapProdByType.get('DepositRetain'));
        prodToQLI.add(mapProdByType.get('RentReview'));
        prodToQLI.add(mapProdByType.get('BuildingInsurance'));
        prodToQLI.add(mapProdByType.get('Guarantor'));
        prodToQLI.add(mapProdByType.get('HalfRent'));
        prodToQLI.add(mapProdByType.get('ServiceCharge'));
        prodToQLI.add(mapProdByType.get('ServiceChargeCap'));
        prodToQLI.add(mapProdByType.get('FitOutCustomer'));
        prodToQLI.add(mapProdByType.get('CustomerBreakOption'));
        prodToQLI.add(mapProdByType.get('CustomerBreakOption'));
        prodToQLI.add(mapProdByType.get('CustomerBreakOption'));

        List<SBQQ__QuoteLine__c> qLines = createQuoteLine(quote, prodToQLI);
        return quote;
    }

    public static User createUser(String name, String profileName) {
        Integer randomInt = Integer.valueOf(Math.rint(Math.random() * 1000000));
        String dateString = String.valueof(Datetime.now()).replace(' ', '').replace(':', '').replace('-', '');
        String username = name + dateString + randomInt;
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = :profileName];
        User testUser = new User(Alias = 'BWstandt', Email = username + '@testorg.com',
                EmailEncodingKey = 'UTF-8', LastName = 'Testing' + getRandomString(), LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = testProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles', UserName = username + '@testorg.com');
        return testUser;
    }

    public static SBQQ__Quote__c generateServicedQuoteWithLines() {
        Map<String, Product2> mapProdByType = new Map<String, Product2>();
        List<SBQQ__QuoteLine__c> qLines = new List<SBQQ__QuoteLine__c>();
        List<Product2> prodToQLI = new List<Product2>();
        SBQQ__Quote__c quote = preGenerateQuote('Serviced');

        mapProdByType = mapProdByType();


        prodToQLI.add(mapProdByType.get('BSLF'));
        prodToQLI.add(mapProdByType.get('BSDP'));
        prodToQLI.add(mapProdByType.get('SteppedRent'));
        prodToQLI.add(mapProdByType.get('SteppedRent'));
        prodToQLI.add(mapProdByType.get('CarParkingLease'));
        prodToQLI.add(mapProdByType.get('BSDM20'));
        prodToQLI.add(mapProdByType.get('BSII'));
        prodToQLI.add(mapProdByType.get('BSHD'));
        prodToQLI.add(mapProdByType.get('BSCB'));
        prodToQLI.add(mapProdByType.get('CarParkLicense'));

        qLines = createQuoteLine(quote, prodToQLI);

        return quote;
    }

    public static SBQQ__Quote__c generateVirtualQuoteWithLines() {
        Map<String, Product2> mapProdByType = new Map<String, Product2>();
        List<SBQQ__QuoteLine__c> qLines = new List<SBQQ__QuoteLine__c>();
        List<Product2> prodToQLI = new List<Product2>();
        SBQQ__Quote__c quote = preGenerateQuote('Virtual');

        mapProdByType = mapProdByType();

        prodToQLI.add(mapProdByType.get('BVLF'));
        prodToQLI.add(mapProdByType.get('BSDP'));
        prodToQLI.add(mapProdByType.get('BVCN'));
        prodToQLI.add(mapProdByType.get('BVCH'));
        prodToQLI.add(mapProdByType.get('BVCF'));
        prodToQLI.add(mapProdByType.get('BVCF'));


        qLines = createQuoteLine(quote, prodToQLI);

        return quote;
    }

    public static SBQQ__Quote__c preGenerateQuote(String RecordType) {
        Pricebook2 price = createPricebook(RecordType);
        Property__c property = createProperty();
        List<Product2> prodList = createProducts();

        Product2 product = [SELECT Id, Name, Family, ProductCode FROM Product2 WHERE Family = 'Suite' and ProductCode = 'OfficeRent' LIMIT 1];

        Inventory__c inventory = createProposedSuiteInventory(product, property);
        Opportunity opp = createOpportunity(RecordType);

        opp.Pricebook2 = price;

        update opp;

        SBQQ__Quote__c quote = createQuote(property, opp, RecordType);

        return quote;
    }

    public static Map<String, Product2> mapProdByType() {
        Map<String, Product2> mapProdByType = new Map<String, Product2>();
        List<Product2> prodList = [
                SELECT ID,ProductCode,Name,Family
                FROM Product2
        ];
        for (Product2 p : prodList) {
            mapProdByType.put(p.ProductCode, p);
        }
        return mapProdByType;
    }

    private static String getRandomString() {
        return String.valueOf(randomWithLimit(1000000));
    }

    public static SBQQ__QuoteLine__c generateLine(Product2 prod, Id quoteId, Id invId, Id lineId) {
        SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c(
                Cap_Expiry_Month__c = 45,
                SBQQ__Quote__c = quoteId,
                SBQQ__Product__c = prod.Id,
                List_Price__c = 1,
                SBQQ__SubscriptionTerm__c = 1,
                SBQQ__Discount__c = 0.01,
                Term__c = 30,
                Monthly_Average__c = 200.0,
                Break_Date__c = 20.0,
                SBQQ__Bundle__c = true,
                SBQQ__Quantity__c = 1,
                Inventory__c = invId
        );
        if (prod.Family == ProductService.PRODUCT_FAMILY_SUITE) {
            quoteLine.Suite_Inventory__c = invId;
            quoteLine.Start_Date__c = Date.today().addMonths(1);
        }

        if (prod.Family != ProductService.PRODUCT_FAMILY_SUITE) {
            quoteLine.Suite_Inventory__c = invId;
            quoteLine.SBQQ__RequiredBy__c = lineId;
        }
        return quoteLine;
    }

    public static SBQQ__Subscription__c createSubscription(SBQQ__QuoteLine__c line, Contract contract){
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c(
                SBQQ__Product__c = line.SBQQ__Product__c,
                Inventory__c = line.Inventory__c,
                SBQQ__Contract__c = contract.Id,
                SBQQ__Quantity__c = 5,
                SBQQ__QuoteLine__c = line.Id
        );
        insert subscription;
        return subscription;
    }
}