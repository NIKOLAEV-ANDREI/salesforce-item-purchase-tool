public with sharing class PurchaseCheckoutController {
    public class CartLineInput {
        @AuraEnabled public Id itemId { get; set; }
        @AuraEnabled public Integer quantity { get; set; }
    }

    @AuraEnabled
    public static Id checkout(Id accountId, List<CartLineInput> lines) {
        if (accountId == null) {
            throw new AuraHandledException('Select an Account before checkout.');
        }
        if (lines == null || lines.isEmpty()) {
            throw new AuraHandledException('The cart is empty.');
        }

        Map<Id, Integer> quantitiesByItemId = new Map<Id, Integer>();
        for (CartLineInput line : lines) {
            if (line == null || line.itemId == null || line.quantity == null || line.quantity <= 0) {
                throw new AuraHandledException('Each cart line must contain an item and a positive quantity.');
            }
            Integer currentQuantity = quantitiesByItemId.containsKey(line.itemId) ? quantitiesByItemId.get(line.itemId) : 0;
            quantitiesByItemId.put(line.itemId, currentQuantity + line.quantity);
        }

        Map<Id, Item__c> itemsById = new Map<Id, Item__c>([
            SELECT Id, Name, Price__c, AvailableQuantity__c
            FROM Item__c
            WHERE Id IN :quantitiesByItemId.keySet()
            FOR UPDATE
        ]);
        if (itemsById.size() != quantitiesByItemId.size()) {
            throw new AuraHandledException('One or more items no longer exist. Refresh the catalog and try again.');
        }

        for (Id itemId : quantitiesByItemId.keySet()) {
            Item__c item = itemsById.get(itemId);
            if (item.AvailableQuantity__c < quantitiesByItemId.get(itemId)) {
                throw new AuraHandledException('Not enough stock for "' + item.Name + '". Refresh the catalog and try again.');
            }
        }

        Purchase__c purchase = new Purchase__c(
            Name = 'Purchase ' + String.valueOf(Datetime.now()),
            ClientId__c = accountId
        );
        insert purchase;

        List<PurchaseLine__c> purchaseLines = new List<PurchaseLine__c>();
        List<Item__c> itemsToUpdate = new List<Item__c>();
        for (Id itemId : quantitiesByItemId.keySet()) {
            Item__c item = itemsById.get(itemId);
            Integer quantity = quantitiesByItemId.get(itemId);
            purchaseLines.add(new PurchaseLine__c(
                PurchaseId__c = purchase.Id,
                ItemId__c = itemId,
                Amount__c = quantity,
                UnitCost__c = item.Price__c
            ));
            item.AvailableQuantity__c -= quantity;
            itemsToUpdate.add(item);
        }
        insert purchaseLines;
        update itemsToUpdate;

        return purchase.Id;
    }
}
