public with sharing class UnsplashImageController {
    @AuraEnabled
    public static String getSuggestedImage(String searchTerm) {
        if (String.isBlank(searchTerm)) {
            throw new AuraHandledException('Enter an item name before requesting an image.');
        }

        UnsplashSettings__c settings = UnsplashSettings__c.getOrgDefaults();
        if (settings == null || String.isBlank(settings.AccessKey__c)) {
            throw new AuraHandledException('Unsplash Access Key is not configured.');
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(
            'https://api.unsplash.com/photos/random?query=' + EncodingUtil.urlEncode(searchTerm.trim(), 'UTF-8') +
            '&orientation=landscape&content_filter=high'
        );
        request.setMethod('GET');
        request.setHeader('Authorization', 'Client-ID ' + settings.AccessKey__c);
        request.setHeader('Accept-Version', 'v1');

        HttpResponse response = new Http().send(request);
        if (response.getStatusCode() != 200) {
            throw new AuraHandledException('Unsplash did not return an image. Try another item name.');
        }

        Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        Map<String, Object> urls = (Map<String, Object>) payload.get('urls');
        String imageUrl = urls == null ? null : (String) urls.get('regular');
        if (String.isBlank(imageUrl)) {
            throw new AuraHandledException('Unsplash returned no usable image URL.');
        }
        return imageUrl;
    }
}
