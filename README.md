# Salesforce Item Purchase Tool

Salesforce application for creating and processing item purchases from an Account record.

## Status

Learning project built with Salesforce metadata, Apex, Lightning Web Components, Flow, and permission sets.

## Business flow

1. Open an Account and launch the **Item Purchase Tool**.
2. Browse the `Item__c` catalog, filter by family or type, search, and add items to the cart.
3. Checkout creates a `Purchase__c` record and `PurchaseLine__c` records.
4. Apex locks inventory rows, validates stock, and decreases `AvailableQuantity__c`.
5. A record-triggered Flow calculates purchase totals. When stock reaches zero, another Flow sends a notification.

## Components

- **LWC**: `itemPurchaseTool` renders the catalog, cart, checkout, Account context, and manager-only item creation.
- **Apex**:
  - `ItemPurchaseController` retrieves a filtered catalog in user mode;
  - `PurchaseCheckoutController` validates the cart, locks items with `FOR UPDATE`, creates purchase records, and updates stock;
  - `UnsplashImageController` retrieves suggested item images;
  - `InventoryNotificationAction` is called by the inventory Flow.
- **Flows**:
  - `PurchaseCalculateTotals` calculates `TotalItems__c` and `GrandTotal__c` after a purchase line is created;
  - `NotifyWhenItemStockEmpty` invokes an Apex action when an item's available quantity changes to zero.
- **Access**: `ItemPurchaseToolAccess` permission set provides object and field permissions.

## Data model

| Object | Purpose |
| --- | --- |
| `Item__c` | Catalog item: description, type, family, image, price, and available quantity |
| `Purchase__c` | Purchase linked to an Account through `ClientId__c`; stores total items and grand total |
| `PurchaseLine__c` | Purchase line linking a purchase and an item; stores quantity and unit cost |
| `InventoryNotificationSettings__c` | Recipients for low-stock notifications |
| `UnsplashSettings__c` | Unsplash access-key configuration |

The LWC is exposed through a custom tab and an Account web link. It reads the custom `User.IsManager__c` field to enable item creation for managers.

## Setup

Requirements:

- Salesforce CLI (`sf`);
- a Salesforce Developer Org;
- VS Code with Salesforce Extension Pack (recommended).

Authenticate and set a default org:

```bash
sf org login web --alias item-purchase-dev --set-default
```

Deploy the project metadata:

```bash
sf project deploy start --source-dir force-app
```

Assign access to a user:

```bash
sf org assign permset --name ItemPurchaseToolAccess
```

To retrieve metadata from the org, use the included manifest:

```bash
sf project retrieve start --manifest manifest/package.xml
```

## Tests

Run Apex tests:

```bash
sf apex run test --test-level RunLocalTests --wait 20
```

The repository contains unit tests for the Apex controllers and inventory notification action.

## Limitations

- The project expects a configured Developer Org, permissions, and required custom metadata/settings.
- External image lookup depends on Unsplash configuration and the corresponding remote site/CSP settings.
- This is an unmanaged learning project; review sharing, permissions, and integration secrets before production use.
