public with sharing class InventoryNotificationAction {
    public class Request {
        @InvocableVariable(required=true)
        public Id itemId;
    }

    @InvocableMethod(label='Notify recipients about empty item stock')
    public static void notifyStockEmpty(List<Request> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        Set<Id> itemIds = new Set<Id>();
        for (Request request : requests) {
            if (request != null && request.itemId != null) {
                itemIds.add(request.itemId);
            }
        }
        if (itemIds.isEmpty()) {
            return;
        }

        Set<Id> recipientIds = getRecipientIds();
        if (recipientIds.isEmpty()) {
            return;
        }

        Map<Id, Item__c> itemsById = new Map<Id, Item__c>([
            SELECT Id, Name, AvailableQuantity__c
            FROM Item__c
            WHERE Id IN :itemIds
        ]);
        if (itemsById.isEmpty()) {
            return;
        }

        CustomNotificationType notificationType = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'Inventory_Stock_Empty'
            LIMIT 1
        ];
        EmailTemplate emailTemplate = [
            SELECT Id
            FROM EmailTemplate
            WHERE DeveloperName = 'Inventory_Stock_Empty' AND Folder.DeveloperName = 'ItemPurchase'
            LIMIT 1
        ];

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (Item__c item : itemsById.values()) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTitle('Item is out of stock');
            notification.setBody(item.Name + ' has reached zero available units.');
            notification.setTargetId(item.Id);
            Set<String> notificationRecipientIds = new Set<String>();
            for (Id recipientId : recipientIds) {
                notificationRecipientIds.add(String.valueOf(recipientId));
            }
            notification.send(notificationRecipientIds);

            for (Id recipientId : recipientIds) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(emailTemplate.Id);
                email.setTargetObjectId(recipientId);
                email.setSaveAsActivity(false);
                emails.add(email);
            }
        }
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }

    @TestVisible
    private static Set<Id> getRecipientIds() {
        InventoryNotificationSettings__c settings = InventoryNotificationSettings__c.getOrgDefaults();
        Set<Id> recipientIds = new Set<Id>();
        if (settings == null || String.isBlank(settings.RecipientUserIds__c)) {
            return recipientIds;
        }

        for (String value : settings.RecipientUserIds__c.split(';')) {
            String userId = value.trim();
            if (String.isNotBlank(userId) && userId.length() == 18) {
                recipientIds.add((Id) userId);
            }
        }
        return recipientIds;
    }
}
