@IsTest
private class PurchaseCheckoutControllerTest {
    @TestSetup
    static void createData() {
        Account account = new Account(Name = 'Checkout Test Account');
        insert account;
        insert new Item__c(
            Name = 'Checkout Test Item',
            Family__c = 'Electronics',
            Type__c = 'Standard',
            Price__c = 25,
            AvailableQuantity__c = 3
        );
    }

    @IsTest
    static void checkoutCreatesPurchaseLinesAndDecreasesStock() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Checkout Test Account' LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Checkout Test Item' LIMIT 1];
        PurchaseCheckoutController.CartLineInput line = new PurchaseCheckoutController.CartLineInput();
        line.itemId = item.Id;
        line.quantity = 2;

        Test.startTest();
        Id purchaseId = PurchaseCheckoutController.checkout(account.Id, new List<PurchaseCheckoutController.CartLineInput>{ line });
        Test.stopTest();

        Purchase__c purchase = [SELECT ClientId__c FROM Purchase__c WHERE Id = :purchaseId];
        PurchaseLine__c purchaseLine = [SELECT PurchaseId__c, ItemId__c, Amount__c, UnitCost__c FROM PurchaseLine__c WHERE PurchaseId__c = :purchaseId];
        Item__c updatedItem = [SELECT AvailableQuantity__c FROM Item__c WHERE Id = :item.Id];
        System.assertEquals(account.Id, purchase.ClientId__c);
        System.assertEquals(item.Id, purchaseLine.ItemId__c);
        System.assertEquals(2, Integer.valueOf(purchaseLine.Amount__c));
        System.assertEquals(25, purchaseLine.UnitCost__c);
        System.assertEquals(1, Integer.valueOf(updatedItem.AvailableQuantity__c));
    }

    @IsTest
    static void checkoutDoesNotCreateRecordsWhenStockIsInsufficient() {
        Account account = [SELECT Id FROM Account WHERE Name = 'Checkout Test Account' LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c WHERE Name = 'Checkout Test Item' LIMIT 1];
        PurchaseCheckoutController.CartLineInput line = new PurchaseCheckoutController.CartLineInput();
        line.itemId = item.Id;
        line.quantity = 4;

        try {
            PurchaseCheckoutController.checkout(account.Id, new List<PurchaseCheckoutController.CartLineInput>{ line });
            System.assert(false, 'Expected an exception for insufficient stock.');
        } catch (AuraHandledException error) {
            // Expected: the controller rejects the checkout before creating records.
        }
        System.assertEquals(0, [SELECT COUNT() FROM Purchase__c]);
        System.assertEquals(0, [SELECT COUNT() FROM PurchaseLine__c]);
    }
}
