import { LightningElement, track, api } from 'lwc';
import getSegments from '@salesforce/apex/EngagementGridSetupController.getSegments';
import saveMetadata from '@salesforce/apex/EngagementGridSetupController.saveMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setRecalculationDue from '@salesforce/apex/EngagementGridSetupController.setRecalculationDue';
export default class SegmentSetup extends LightningElement {
	@api
	recalculationIsDue;
	@track
	segments = [];
	loading = true;

	connectedCallback() {
		this.getSegments();
	}

	onChangeHandler(event) {
		const { name } = event.target;
		const devName = name.split('-')[0];
		const key = name.split('-')[1];
		this.segments.map((s) => {
			if (s.DeveloperName === devName) {
				s[key] = event.target.value;
			}
			return s;
		});
	}

	onSubmitHandler() {
		const segments = this.segments.map((s) => ({
			Id: s.Id,
			Colour__c: s.Colour__c,
			MasterLabel: s.MasterLabel,
			DeveloperName: s.DeveloperName
		}));
		saveMetadata({ metadata: segments })
			.then(() => {
				const evt = new ShowToastEvent({
					title: 'Success',
					message: 'Segments Saved',
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
				setRecalculationDue().finally(this.recalculationIsDue());
			});
	}

	getSegments() {
		this.loading = true;
		this.segments = null;
		getSegments()
			.then((result) => {
				this.segments = result.map((s) => {
					return {
						...s,
						colourID: s.DeveloperName + '-Colour__c',
						masterLabelID: s.DeveloperName + '-MasterLabel'
					};
				});
				this.loading = false;
			})
			.catch((e) => {
				const evt = new ShowToastEvent({
					title: 'Error',
					message: e.message,
					variant: 'error'
				});
				this.dispatchEvent(evt);
				console.log(e);
				this.loading = false;
			});
	}
}
