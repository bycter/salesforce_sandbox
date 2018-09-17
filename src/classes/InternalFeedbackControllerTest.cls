@isTest
public with sharing class InternalFeedbackControllerTest {
    @isTest
    public static void internalFeedbackTest(){
        Test.startTest();
        Case outsourcedCase = new Case();
        ApexPages.StandardController sc = new ApexPages.StandardController(outsourcedCase);
        InternalFeedbackController c = new InternalFeedbackController(sc);
        c.getCaseLink();
        Test.stopTest();
    }
}