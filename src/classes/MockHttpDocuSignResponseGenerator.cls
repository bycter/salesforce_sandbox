@isTest
global class MockHttpDocuSignResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // System.assertEquals(DocuSignIntegrator.HTTP_PUT_METHOD, req.getMethod(), 'Incorrect HTTP method is requested from Docusign');
        System.assert(!String.isBlank(req.getHeader(DocuSignIntegrator.HTTP_AUTHENTICATION_HEADER)), 'Authentication header must be filled');

        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader(DocuSignIntegrator.HTTP_CONTENT_TYPE_HEADER, DocuSignIntegrator.HTTP_APPLICATION_JSON);
        res.setBody('{"success": true}');
        res.setStatusCode(200);
        return res;
    }
}