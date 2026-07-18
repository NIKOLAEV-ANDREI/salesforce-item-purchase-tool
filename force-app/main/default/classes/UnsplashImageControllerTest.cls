@IsTest
private class UnsplashImageControllerTest {
    private class UnsplashMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assert(request.getEndpoint().contains('photos/random'));
            System.assertEquals('Client-ID test-access-key', request.getHeader('Authorization'));
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"urls":{"regular":"https://images.unsplash.com/example-image"}}');
            return response;
        }
    }

    @IsTest
    static void returnsRegularImageUrlFromUnsplash() {
        insert new UnsplashSettings__c(
            Name = 'Organization',
            SetupOwnerId = UserInfo.getOrganizationId(),
            AccessKey__c = 'test-access-key'
        );
        Test.setMock(HttpCalloutMock.class, new UnsplashMock());

        Test.startTest();
        String imageUrl = UnsplashImageController.getSuggestedImage('office chair');
        Test.stopTest();

        System.assertEquals('https://images.unsplash.com/example-image', imageUrl);
    }

    @IsTest
    static void rejectsRequestWhenAccessKeyIsNotConfigured() {
        try {
            UnsplashImageController.getSuggestedImage('office chair');
            System.assert(false, 'Expected an error when the Access Key is missing.');
        } catch (AuraHandledException error) {
            System.assertNotEquals(null, error);
        }
    }
}
