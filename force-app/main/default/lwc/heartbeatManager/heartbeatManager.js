/* eslint-disable @lwc/lwc/no-async-operation */
import { api, LightningElement } from 'lwc';
import getCurrentHeartbeat from '@salesforce/apex/EngagementGridSetupController.getCurrentHeartbeat';
import runFirstJob from '@salesforce/apex/EngagementGridSetupController.runFirstJob';
import scheduleHeartbeat from '@salesforce/apex/EngagementGridSetupController.scheduleHeartbeat';
import deleteHeartbeat from '@salesforce/apex/EngagementGridSetupController.deleteHeartbeat';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import setRecalculationNotDue from '@salesforce/apex/EngagementGridSetupController.setRecalculationNotDue';

export default class heartbeatManager extends LightningElement {
	@api
	loadSettings;
	@api
	recalculationNotDue;

	className = 'CalculateRFMQueueableBeat';
	startingHour;
	scheduledStartingHour;
	loading = true;
	heartbeatScheduled = false;

	get formattedHour() {
		if (this.scheduledStartingHour) {
			return `${String(this.scheduledStartingHour).padStart(2, '0')}:00`;
		}
		return '';
	}

	get hours() {
		return Array.from(Array(24).keys()).map((i) => ({ label: `${String(i).padStart(2, '0')}:00`, value: String(i) }));
	}

	connectedCallback() {
		this.getScheduledHB();
	}

	getScheduledHB() {
		getCurrentHeartbeat({ className: this.className })
			.then((result) => {
				if (result.length > 0) {
					this.heartbeatScheduled = true;
					this.scheduledStartingHour = result[0].cpm__Starting_Hour__c;
				}
			})
			.catch((error) => {
				console.log(error.message);
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

	runFirstJob() {
		this.loading = true;
		runFirstJob({})
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
				setRecalculationNotDue().finally(this.recalculationNotDue);
			});
	}

	scheduleHeartbeat() {
		this.loading = true;
		scheduleHeartbeat({
			className: this.className,
			startingHour: this.startingHour
		})
			.then(() => {
				this.getScheduledHB();
			})
			.catch((error) => {
				console.log(error);
				console.log(error.message);
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

	deleteHB() {
		this.loading = true;
		deleteHeartbeat({ className: this.className })
			.then((data) => {
				if (data) {
					const evt = new ShowToastEvent({
						title: 'Success',
						message: 'Heartbeat deleted successfully',
						variant: 'success'
					});
					this.heartbeatScheduled = false;
					this.scheduledStartingHour = null;
					this.dispatchEvent(evt);
				}
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

	onChangeHandler(event) {
		this[event.target.name] = event.detail.value;
	}
}
