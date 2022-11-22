/* eslint-disable @lwc/lwc/no-async-operation */
import { LightningElement } from 'lwc';
import getJobProgress from '@salesforce/apex/EngagementGridController.getJobProgress';
import getStats from '@salesforce/apex/EngagementGridController.getStats';
import getRanges from '@salesforce/apex/EngagementGridController.getRanges';
import getSegments from '@salesforce/apex/EngagementGridController.getSegments';
import recalculateRFM from '@salesforce/apex/EngagementGridController.recalculateRFM';
import getSettings from '@salesforce/apex/EngagementGridSetupController.getSettings';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Monetary_Value_Text from '@salesforce/label/c.Monetary_Value_Text';
import Customer_Label from '@salesforce/label/c.Customer_Label';
import Customer_Singular_Label from '@salesforce/label/c.Customer_Singular_Label';

const yAxisLabels = {
	EngGrid_Frequency_Score__c: 'Frequency',
	EngGrid_Monetary_Score__c: 'Monetary Value'
};
export default class EngagementGrid extends LightningElement {
	labels = {
		Monetary_Value_Text
	};
	loaded = false;
	tiles = {};
	reportId = null;

	yAxis = 'EngGrid_Frequency_Score__c';

	xAxisLabel = 'Recency';
	yAxisLabel = yAxisLabels[this.yAxis];

	xAxisValues = [];
	yAxisValues = [];

	refreshJobInProgress = false;
	refreshJobId = null;
	refreshJobDone = false;
	refreshJobProgress = 0;

	noReportOnclick() {
		const evt = new ShowToastEvent({
			title: 'No Report',
			message: 'No report has been configured for this engagement grid, please set a default report in the settings.',
			variant: 'error'
		});
		this.dispatchEvent(evt);
	}

	async getData() {
		this.loaded = false;
		this.xAxisValues = [];
		this.yAxisValues = [];
		Promise.all([getSettings(), getSegments(), getStats(), getRanges()])
			.then(([settings, segments, result, ranges]) => {
				this.reportId = settings.Report_Id__c || '';
				segments.forEach((s) => {
					const percentage = Math.round((result[s.MasterLabel] / result.total) * 100 * 100) / 100;
					const onClick = this.reportId ? () => window.open(`/lightning/r/${this.reportId}/view?fv0=${s.MasterLabel}`, '_blank') : this.noReportOnclick;
					this.tiles[s.DeveloperName] = {
						title: s.MasterLabel,
						description: `0 ${Customer_Label} (0%)`,
						monetaryVal: result[s.MasterLabel + ' Average'],
						inlineStyle: `background-color: ${s.Colour__c}`,
						onClick
					};

					if(result[s.MasterLabel]) {
						if (result[s.MasterLabel] == 1) {
							this.tiles[s.DeveloperName].description = `${result[s.MasterLabel]} ${Customer_Singular_Label} (${percentage}%)`;
						} else {
							this.tiles[s.DeveloperName].description = `${result[s.MasterLabel]} ${Customer_Label} (${percentage}%)`;
						}
					}
				});
				this.yAxis = settings.Y_Axis__c || 'EngGrid_Frequency_Score__c';
				this.yAxisLabel = yAxisLabels[this.yAxis];
				ranges.forEach((e) => {
					this.xAxisValues.push(e.Recency_Range__c);
					this.yAxisValues.push(e[this.yAxis === 'EngGrid_Frequency_Score__c' ? 'Frequency_Range__c' : 'Monetary_Range__c']);
				});
				this.loaded = true;
			})
			.catch((error) => {
				console.log(error);
			});
	}

	async connectedCallback() {
		await this.getData();
	}

	refreshProgress() {
		getJobProgress({ jobId: this.refreshJobId }).then((result) => {
			if (result.total > 0) {
				this.refreshJobProgress = Math.round(((result.done + result.failed) / result.total) * 100 * 100) / 100;
				if (result.done + result.failed === result.total) {
					this.refreshJobDone = true;
					this.refreshJobInProgress = false;
					this.refreshJobProgress = 100;
					this.getData();
				}
			}
		});
	}

	async reCalculateHandler() {
		this.refreshJobInProgress = true;
		recalculateRFM()
			.then((jobId) => {
				this.refreshJobId = jobId;
				let interval = setInterval(() => {
					this.refreshProgress();
					if (this.refreshJobDone) {
						clearInterval(interval);
					}
				}, 200);
			})
			.catch((error) => {
				console.log(error);
			});
	}
}
