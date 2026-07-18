public with sharing class ItemPurchaseController {
    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(String family, String type, String searchTerm) {
        List<String> conditions = new List<String>();
        Map<String, Object> bindValues = new Map<String, Object>();

        if (String.isNotBlank(family)) {
            conditions.add('Family__c = :family');
            bindValues.put('family', family.trim());
        }

        if (String.isNotBlank(type)) {
            conditions.add('Type__c = :type');
            bindValues.put('type', type.trim());
        }

        if (String.isNotBlank(searchTerm)) {
            conditions.add('(Name LIKE :searchPattern OR Description__c LIKE :searchPattern)');
            bindValues.put('searchPattern', '%' + searchTerm.trim() + '%');
        }

        String query =
            'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c, AvailableQuantity__c ' +
            'FROM Item__c';

        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Name ASC';
        return Database.queryWithBinds(query, bindValues, AccessLevel.USER_MODE);
    }
}
