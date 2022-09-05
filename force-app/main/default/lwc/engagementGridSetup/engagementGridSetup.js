import { LightningElement, track } from 'lwc';
import getSettings from '@salesforce/apex/EngagementGridSetupController.getSettings';
import saveMetadata from '@salesforce/apex/EngagementGridSetupController.saveMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class EngagementGridSetup extends LightningElement {
	yAxisOptions = [
		{ label: 'Recency / Frequency', value: 'Frequency_Score__c' },
		{ label: 'Recency / Monetary Value', value: 'Monetary_Score__c' }
	];

	loading = true;
	@track
	settings = {};
	d = new Date(new Date().setFullYear(new Date().getFullYear() - 1));
	oneYearAgo = this.d.toISOString().split('T')[0];

	connectedCallback() {
		this.loadSettings();
	}

	recalculationIsDue = () => {
		this.settings.Re_Calculation_Due__c = true;
	};

	recalculationNotDue = () => {
		this.settings.Re_Calculation_Due__c = false;
	};

	loadSettings = () => {
		getSettings()
			.then((result) => {
				this.settings = result;
			})
			.catch((e) => {
				console.log(e);
				const evt = new ShowToastEvent({
					title: 'Error',
					message: e.message,
					variant: 'error'
				});
				this.dispatchEvent(evt);
			})
			.finally(() => {
				this.loading = false;
			});
	};

	onChangeHandler(e) {
		this.settings[e.target.name] = e.target.value;
		if (e.target.name === 'Date_Range_Start__c') {
			this.settings.Re_Calculation_Due__c = true;
		}
	}

	onSubmitHandler = () => {
		saveMetadata({ metadata: [this.settings] })
			.then(() => {
				const evt = new ShowToastEvent({
					title: 'Success',
					message: 'Settings Saved',
					variant: 'success'
				});
				this.dispatchEvent(evt);
			})
			.catch((e) => {
				const evt = new ShowToastEvent({
					title: 'Error',
					message: e.message,
					variant: 'error'
				});
				this.dispatchEvent(evt);
				console.log(e);
			})
			.finally(() => {
				this.loadSettings();
			});
	};
}
