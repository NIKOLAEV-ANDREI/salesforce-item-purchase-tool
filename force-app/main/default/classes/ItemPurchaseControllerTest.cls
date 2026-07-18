@IsTest
private class ItemPurchaseControllerTest {
    @TestSetup
    static void createItems() {
        insert new List<Item__c>{
            new Item__c(
                Name = 'Business Laptop',
                Description__c = 'Portable computer for office work',
                Family__c = 'Electronics',
                Type__c = 'Premium',
                Price__c = 1200,
                AvailableQuantity__c = 5
            ),
            new Item__c(
                Name = 'Ergonomic Chair',
                Description__c = 'Comfortable chair for a desk',
                Family__c = 'Furniture',
                Type__c = 'Standard',
                Price__c = 250,
                AvailableQuantity__c = 0
            ),
            new Item__c(
                Name = 'Paper Notebook',
                Description__c = 'Notebook for meeting notes',
                Family__c = 'Office Supplies',
                Type__c = 'Standard',
                Price__c = 5,
                AvailableQuantity__c = 20
            )
        };
    }

    @IsTest
    static void getItems_filtersByFamilyAndType() {
        Test.startTest();
        List<Item__c> items = ItemPurchaseController.getItems('Electronics', 'Premium', null);
        Test.stopTest();

        System.assertEquals(1, items.size());
        System.assertEquals('Business Laptop', items[0].Name);
    }

    @IsTest
    static void getItems_searchesNameAndDescription() {
        Test.startTest();
        List<Item__c> nameMatches = ItemPurchaseController.getItems(null, null, 'chair');
        List<Item__c> descriptionMatches = ItemPurchaseController.getItems(null, null, 'meeting');
        Test.stopTest();

        System.assertEquals(1, nameMatches.size());
        System.assertEquals('Ergonomic Chair', nameMatches[0].Name);
        System.assertEquals(1, descriptionMatches.size());
        System.assertEquals('Paper Notebook', descriptionMatches[0].Name);
    }
}
