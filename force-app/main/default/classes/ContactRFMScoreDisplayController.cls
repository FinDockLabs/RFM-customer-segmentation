public with sharing class ContactRFMScoreDisplayController {
	public ContactRFMScoreDisplayController() {
	}

	public static Boolean isMultiCurrency() {
		return UserInfo.isMultiCurrencyOrganization();
	}

	@AuraEnabled
	public static Map<String, Object> calculateRFMSingleContact(Id recordId) {
		Engagement_Grid_Setting__mdt setting = EngagementGridSetupController.getSettings();
		Date collDate = (setting.Date_Range_Start__c != null) ? setting.Date_Range_Start__c : date.today().addYears(-10);
		Map<String, Object> rfmScore = new Map<String, Object>();
		String recordTypeReceivable = [SELECT Id FROM RecordType WHERE DeveloperName = 'Receivable' AND SObjectType = 'cpm__Installment__c'][0].Id;

		CalculateRFMJob job = new CalculateRFMJob();

		Contact c = [
			SELECT
				id,
				Recency_Score__c,
				Frequency_Score__c,
				Monetary_Score__c,
				RFM_Segment__c,
				(
					SELECT Id, cpm__Amount__c, cpm__Collection_Date__c
					FROM cpm__Payments__r
					WHERE cpm__Collection_Date__c >= :collDate AND cpm__Installment__r.cpm__Status__c = 'Collected' AND cpm__Installment__r.RecordTypeId = :recordTypeReceivable
					ORDER BY cpm__Collection_Date__c DESC
				)
			FROM Contact
			WHERE Id = :recordId
		];

		if (c.cpm__Payments__r.size() == 0) {
			return new Map<String, String>{ 'status' => 'No payments found' };
		}
		job.calculateScores(c);
		job.calculateSegment(c);

		update c;

		Decimal totalSum = 0;

		for (cpm__Payment__c p : c.cpm__Payments__r) {
			totalSum += p.cpm__Amount__c;
		}

		String colour = [SELECT Colour__c FROM Engagement_Grid_Segment__mdt WHERE Label = :c.RFM_Segment__c][0].Colour__c;

		rfmScore.put('status', 'success');
		rfmScore.put('r', c.Recency_Score__c);
		rfmScore.put('r_detail', String.valueOf(c.cpm__Payments__r[0].cpm__Collection_Date__c.daysBetween(Date.today())));
		rfmScore.put('f', c.Frequency_Score__c);
		rfmScore.put('f_detail', String.valueOf(c.cpm__Payments__r.size()));
		rfmScore.put('m', c.Monetary_Score__c);
		rfmScore.put('m_detail', String.valueOf(totalSum.setScale(2)));
		rfmScore.put('segment', c.RFM_Segment__c);
		rfmScore.put('max', job.recencyRanges.size());
		rfmScore.put('colour', colour);
		return rfmScore;
	}
}