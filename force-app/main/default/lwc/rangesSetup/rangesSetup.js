import { LightningElement, api } from 'lwc';
import getRanges from '@salesforce/apex/EngagementGridController.getRanges';
import saveMetadata from '@salesforce/apex/EngagementGridSetupController.saveMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setRecalculationDue from '@salesforce/apex/EngagementGridSetupController.setRecalculationDue';

export default class RangesSetup extends LightningElement {
	@api
	recalculationIsDue;

	loading = true;
	ranges = [];

	loadRanges() {
		getRanges()
			.then((result) => {
				this.ranges = [...result]
					.sort((a, b) => a.Order__c - b.Order__c)
					.map((r) => ({
						...r,
						rRangeID: r.DeveloperName + '-Recency_Range__c',
						fRangeID: r.DeveloperName + '-Frequency_Range__c',
						mRangeID: r.DeveloperName + '-Monetary_Range__c'
					}));
			})
			.catch((error) => {
				console.log(error);
				const evt = new ShowToastEvent({
					title: 'Error',
					message: error.message,
					variant: 'error'
				});
				this.dispatchEvent(evt);
			})
			.finally(() => {
				this.loading = false;
			});
	}

	connectedCallback() {
		this.loadRanges();
	}

	onChangeHandler(e) {
		const { name } = e.target;
		const devName = name.split('-')[0];
		const key = name.split('-')[1];
		this.ranges.map((r) => {
			if (r.DeveloperName === devName) {
				r[key] = e.target.value;
			}
			return r;
		});
	}
	onSubmitHandler() {
		const ranges = this.ranges.map((r) => ({
			Id: r.Id,
			DeveloperName: r.DeveloperName,
			MasterLabel: r.MasterLabel,
			Recency_Range__c: r.Recency_Range__c,
			Frequency_Range__c: r.Frequency_Range__c,
			Monetary_Range__c: r.Monetary_Range__c
		}));
		saveMetadata({ metadata: ranges })
			.then(() => {
				const evt = new ShowToastEvent({
					title: 'Success',
					message: 'Ranges Saved',
					variant: 'success'
				});
				this.dispatchEvent(evt);
				setRecalculationDue().finally(this.recalculationIsDue);
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
				this.loading = false;
			});
	}
}
