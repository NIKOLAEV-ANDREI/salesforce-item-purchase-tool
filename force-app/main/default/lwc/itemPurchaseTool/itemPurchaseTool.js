import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_NAME from '@salesforce/schema/Account.Name';
import ACCOUNT_NUMBER from '@salesforce/schema/Account.AccountNumber';
import ACCOUNT_INDUSTRY from '@salesforce/schema/Account.Industry';

const ACCOUNT_FIELDS = [ACCOUNT_NAME, ACCOUNT_NUMBER, ACCOUNT_INDUSTRY];

export default class ItemPurchaseTool extends LightningElement {
    recordId;

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
}
