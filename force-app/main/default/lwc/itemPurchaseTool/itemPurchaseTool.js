import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_NUMBER from '@salesforce/schema/Account.AccountNumber';
import ACCOUNT_INDUSTRY from '@salesforce/schema/Account.Industry';
import getItems from '@salesforce/apex/ItemPurchaseController.getItems';

const ACCOUNT_FIELDS = [ACCOUNT_NAME, ACCOUNT_NUMBER, ACCOUNT_INDUSTRY];

export default class ItemPurchaseTool extends LightningElement {
    recordId;
    items = [];
    filterSourceItems = [];
    selectedFamily = '';
    selectedType = '';
    searchTerm = '';
    selectedItemId;
    isLoading = false;
    filterOptionsLoaded = false;
    searchTimeout;

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

    async loadItems() {
        this.isLoading = true;

        try {
            const items = await getItems({
                family: this.selectedFamily || null,
                type: this.selectedType || null,
                searchTerm: this.searchTerm || null
            });

            this.items = items;
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

    toOptions(fieldName, allLabel) {
        const values = [...new Set(this.filterSourceItems.map((item) => item[fieldName]).filter(Boolean))].sort();
        return [{ label: allLabel, value: '' }, ...values.map((value) => ({ label: value, value }))];
    }
}
