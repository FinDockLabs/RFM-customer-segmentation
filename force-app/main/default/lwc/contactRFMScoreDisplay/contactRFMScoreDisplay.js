import { LightningElement, api } from 'lwc';
import calculateRFMSingleContact from '@salesforce/apex/ContactRFMScoreDisplayController.calculateRFMSingleContact';
import Contact_RFM_Scoring from '@salesforce/label/c.Contact_RFM_Scoring';
import Recency from '@salesforce/label/c.Recency';
import Recency_Description from '@salesforce/label/c.Recency_Description';
import Frequency from '@salesforce/label/c.Frequency';
import Frequency_Description from '@salesforce/label/c.Frequency_Description';
import Monetary_Value from '@salesforce/label/c.Monetary_Value';
import Monetary_Value_Description from '@salesforce/label/c.Monetary_Value_Description';
import No_Payment_Text from '@salesforce/label/c.No_Payment_Text';

export default class ContactRFMScoreDisplay extends LightningElement {
	labels = {
		Contact_RFM_Scoring,
		Recency,
		Recency_Description,
		Frequency,
		Frequency_Description,
		Monetary_Value,
		No_Payment_Text,
		Monetary_Value_Before: Monetary_Value_Description.split('{!value}')[0] || '',
		Monetary_Value_After: Monetary_Value_Description.split('{!value}')[1] || ''
	};

	@api
	recordId;

	segmentStyle = 'border-radius: 5px; ';

	loading = true;

	noPayments = false;

	r = 0;
	f = 0;
	m = 0;
	m_value = 0;
	segment = '';
	max = 0;

	connectedCallback() {
		calculateRFMSingleContact({ recordId: this.recordId })
			.then((result) => {
				if (!result.f) {
					this.noPayments = true;
					return;
				}
				this.r = result.r;
				this.labels.Recency_Description = this.labels.Recency_Description.replace('{!value}', result.r_detail);
				this.f = result.f;
				this.labels.Frequency_Description = this.labels.Frequency_Description.replace('{!value}', result.f_detail);
				this.m = result.m;
				this.m_value = result.m_detail;
				this.segment = result.segment;
				this.segmentStyle += `background-color: ${result.colour}`;
				this.max = result.max;
			})
			.catch((error) => {
				console.log(error);
			})
			.finally(() => {
				this.loading = false;
			});
	}
}
