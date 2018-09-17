@isTest
public class GenerateQuoteControllerTest {

    @isTest
    public static void generateQuoteTest(){
        Test.startTest();
        SBQQ__Quote__c quote = RecordDmlTest.createCPQQuote();
        Test.stopTest();
    }

}