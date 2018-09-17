@isTest
public class DocuSignIntegratorTest {

    @testSetup
    public static void initData() {
        RecordDmlTest.createDocusignSettings();
    }

    @isTest
    public static void testVoidEnvelope() {
        Test.setMock(HttpCalloutMock.class, new MockHttpDocuSignResponseGenerator());
        DocuSignIntegrator.voidEnvelope('testEnvelopeId');
    }
}