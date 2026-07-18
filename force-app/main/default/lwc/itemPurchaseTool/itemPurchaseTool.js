import { LightningElement, wire } from 'lwc';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_NUMBER from '@salesforce/schema/Account.AccountNumber';
import ACCOUNT_INDUSTRY from '@salesforce/schema/Account.Industry';
import getItems from '@salesforce/apex/ItemPurchaseController.getItems';
import checkout from '@salesforce/apex/PurchaseCheckoutController.checkout';
import getSuggestedImage from '@salesforce/apex/UnsplashImageController.getSuggestedImage';
import IS_MANAGER from '@salesforce/schema/User.IsManager__c';

const ACCOUNT_FIELDS = [ACCOUNT_NAME, ACCOUNT_NUMBER, ACCOUNT_INDUSTRY];

export default class ItemPurchaseTool extends NavigationMixin(LightningElement) {
    recordId;
    items = [];
    filterSourceItems = [];
    selectedFamily = '';
    selectedType = '';
    searchTerm = '';
    selectedItemId;
    isLoading = false;
    isCheckingOut = false;
    isSavingItem = false;
    showCart = false;
    isItemFormOpen = false;
    filterOptionsLoaded = false;
    searchTimeout;
    cartItems = [];

    connectedCallback() {
        this.loadItems();
    }

    disconnectedCallback() {
        clearTimeout(this.searchTimeout);
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(pageReference) {
        this.recordId = pageReference?.state?.c__recordId;
    }

    @wire(getRecord, { recordId: '$recordId', fields: ACCOUNT_FIELDS })
    account;

    @wire(getRecord, { recordId: USER_ID, fields: [IS_MANAGER] })
    currentUser;

    get hasRecordId() {
        return Boolean(this.recordId);
    }

    get hasAccount() {
        return Boolean(this.account.data);
    }

    get accountName() {
        return getFieldValue(this.account.data, ACCOUNT_NAME);
    }

    get accountNumber() {
        return getFieldValue(this.account.data, ACCOUNT_NUMBER) || 'Not specified';
    }

    get accountIndustry() {
        return getFieldValue(this.account.data, ACCOUNT_INDUSTRY) || 'Not specified';
    }

    get errorMessage() {
        return this.account.error?.body?.message || 'Unable to load account data.';
    }

    get itemCount() {
        return this.items.length;
    }

    get hasItems() {
        return this.items.length > 0;
    }

    get familyOptions() {
        return this.toOptions('Family__c', 'All families');
    }

    get typeOptions() {
        return this.toOptions('Type__c', 'All types');
    }

    get selectedItem() {
        return this.items.find((item) => item.Id === this.selectedItemId);
    }

    get isDetailsOpen() {
        return Boolean(this.selectedItemId);
    }

    get selectedItemImageUrl() {
        return this.selectedItem?.Image__c;
    }

    get cartItemCount() {
        return this.cartItems.reduce((total, item) => total + item.quantity, 0);
    }

    get cartTotal() {
        return this.cartItems.reduce((total, item) => total + item.lineTotal, 0);
    }

    get hasCartItems() {
        return this.cartItems.length > 0;
    }

    get isCartOpen() {
        return this.showCart;
    }

    get isCheckoutDisabled() {
        return !this.hasCartItems || this.isCheckingOut;
    }

    get isManager() {
        return getFieldValue(this.currentUser.data, IS_MANAGER) === true;
    }

    async loadItems() {
        this.isLoading = true;

        try {
            const items = await getItems({
                family: this.selectedFamily || null,
                type: this.selectedType || null,
                searchTerm: this.searchTerm || null
            });

            this.items = items.map((item) => ({ ...item, isOutOfStock: item.AvailableQuantity__c <= 0 }));
            if (!this.filterOptionsLoaded) {
                this.filterSourceItems = items;
                this.filterOptionsLoaded = true;
            }
        } catch (error) {
            this.items = [];
            this.error = error;
        } finally {
            this.isLoading = false;
        }
    }

    handleFilterChange(event) {
        this[event.target.name] = event.detail.value;
        this.loadItems();
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => this.loadItems(), 300);
    }

    openDetails(event) {
        this.selectedItemId = event.currentTarget.dataset.id;
    }

    closeDetails() {
        this.selectedItemId = undefined;
    }

    addToCart(event) {
        const item = this.items.find((catalogItem) => catalogItem.Id === event.currentTarget.dataset.id);
        if (!item || item.AvailableQuantity__c <= 0) {
            this.showToast('Item unavailable', 'This item is out of stock.', 'error');
            return;
        }

        const existingItem = this.cartItems.find((cartItem) => cartItem.itemId === item.Id);
        if (existingItem) {
            if (existingItem.quantity >= item.AvailableQuantity__c) {
                this.showToast('Stock limit reached', 'You cannot add more than the available quantity.', 'warning');
                return;
            }
            this.cartItems = this.cartItems.map((cartItem) =>
                cartItem.itemId === item.Id
                    ? { ...cartItem, quantity: cartItem.quantity + 1, lineTotal: (cartItem.quantity + 1) * cartItem.unitCost }
                    : cartItem
            );
        } else {
            this.cartItems = [
                ...this.cartItems,
                {
                    itemId: item.Id,
                    name: item.Name,
                    quantity: 1,
                    unitCost: item.Price__c,
                    lineTotal: item.Price__c,
                    availableQuantity: item.AvailableQuantity__c
                }
            ];
        }

        this.showToast('Added to cart', `${item.Name} was added to the cart.`, 'success');
    }

    openCart() {
        this.showCart = true;
    }

    closeCart() {
        this.showCart = false;
    }

    removeFromCart(event) {
        this.cartItems = this.cartItems.filter((item) => item.itemId !== event.currentTarget.dataset.id);
    }

    async handleCheckout() {
        this.isCheckingOut = true;
        try {
            const purchaseId = await checkout({
                accountId: this.recordId,
                lines: this.cartItems.map((item) => ({ itemId: item.itemId, quantity: item.quantity }))
            });
            this.showToast('Purchase created', 'Stock was updated and the purchase was created.', 'success');
            this.cartItems = [];
            this.closeCart();
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: { recordId: purchaseId, objectApiName: 'Purchase__c', actionName: 'view' }
            });
        } catch (error) {
            this.showToast('Checkout failed', error.body?.message || 'Unable to create the purchase.', 'error');
        } finally {
            this.isCheckingOut = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    openItemForm() {
        this.isItemFormOpen = true;
    }

    closeItemForm() {
        if (!this.isSavingItem) {
            this.isItemFormOpen = false;
        }
    }

    async handleItemSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        this.isSavingItem = true;

        try {
            fields.Image__c = await getSuggestedImage({ searchTerm: fields.Name });
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        } catch (error) {
            this.isSavingItem = false;
            this.showToast('Image request failed', error.body?.message || 'Unable to get an image from Unsplash.', 'error');
        }
    }

    handleItemSuccess() {
        this.isSavingItem = false;
        this.isItemFormOpen = false;
        this.filterOptionsLoaded = false;
        this.loadItems();
        this.showToast('Item created', 'A new catalog item with an Unsplash image was created.', 'success');
    }

    handleItemError(event) {
        this.isSavingItem = false;
        this.showToast('Item creation failed', event.detail.message, 'error');
    }

    toOptions(fieldName, allLabel) {
        const values = [...new Set(this.filterSourceItems.map((item) => item[fieldName]).filter(Boolean))].sort();
        return [{ label: allLabel, value: '' }, ...values.map((value) => ({ label: value, value }))];
    }
}
