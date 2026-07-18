@IsTest
private class InventoryNotificationActionTest {
    @IsTest
    static void readsRecipientIdsFromOrganizationSetting() {
        insert new InventoryNotificationSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RecipientUserIds__c = UserInfo.getUserId() + '; 005000000000000AAA'
        );

        Set<Id> recipientIds = InventoryNotificationAction.getRecipientIds();

        System.assertEquals(2, recipientIds.size());
        System.assert(recipientIds.contains(UserInfo.getUserId()));
    }

    @IsTest
    static void doesNothingWhenRecipientsAreNotConfigured() {
        Item__c item = new Item__c(
            Name = 'Notification Test Item',
            Family__c = 'Electronics',
            Type__c = 'Standard',
            Price__c = 10,
            AvailableQuantity__c = 0
        );
        insert item;
        InventoryNotificationAction.Request request = new InventoryNotificationAction.Request();
        request.itemId = item.Id;

        Test.startTest();
        InventoryNotificationAction.notifyStockEmpty(new List<InventoryNotificationAction.Request>{ request });
        Test.stopTest();
    }

    @IsTest
    static void sendsConfiguredRecipientAnEmailAndBellNotification() {
        insert new InventoryNotificationSettings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            RecipientUserIds__c = UserInfo.getUserId()
        );
        Item__c item = new Item__c(
            Name = 'Out Of Stock Test Item',
            Family__c = 'Office Supplies',
            Type__c = 'Standard',
            Price__c = 15,
            AvailableQuantity__c = 0
        );
        insert item;
        InventoryNotificationAction.Request request = new InventoryNotificationAction.Request();
        request.itemId = item.Id;

        Test.startTest();
        InventoryNotificationAction.notifyStockEmpty(new List<InventoryNotificationAction.Request>{ request });
        System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
}
