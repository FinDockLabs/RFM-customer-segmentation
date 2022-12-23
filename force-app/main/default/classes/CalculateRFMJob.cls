@JsonAccess(serializable='always' deserializable='always')
global with sharing class CalculateRFMJob extends cpm.BaseJobGlobal {
	global CalculateRFMJob() {
		List<Engagement_Grid_Range__mdt> rangesMetadata = [
			SELECT Order__c, Recency_Range__c, Frequency_Range__c, Monetary_Range__c
			FROM Engagement_Grid_Range__mdt
			ORDER BY Order__c
		];
		this.segments = [SELECT Label, Min_RFM_Score__c, Max_RFM_Score__c FROM Engagement_Grid_Segment__mdt];

		for (Engagement_Grid_Range__mdt m : rangesMetadata) {
			Range recency = extractRangeFromString(m.Recency_Range__c);
			Range frequency = extractRangeFromString(m.Frequency_Range__c);
			Range monetary = extractRangeFromString(m.Monetary_Range__c);
			this.recencyRanges.add(recency);
			this.frequencyRanges.add(frequency);
			this.monetaryRanges.add(monetary);
		}
	}
	global List<Range> recencyRanges = new List<Range>();
	global List<Range> frequencyRanges = new List<Range>();
	global List<Range> monetaryRanges = new List<Range>();
	global List<Engagement_Grid_Segment__mdt> segments = new List<Engagement_Grid_Segment__mdt>();
	global String segmentColor;

	global override void doExecute(QueueableContext context) {
		Engagement_Grid_Setting__mdt setting = EngagementGridSetupController.getSettings();
		Date collDate = (setting.Date_Range_Start__c != null) ? setting.Date_Range_Start__c : date.today().addYears(-10);
		Map<String, Object> job_info = (Map<String, Object>) JSON.deserializeUntyped(this.getByJobId(context.getJobId()).cpm__payload__c);
		Id startingId = (Id) job_info.get('startingId');
		String recordTypeReceivable = (String) job_info.get('recordTypeReceivable');
		Integer numberOfRecords = (Integer) job_info.get('numberOfRecords');

		List<Contact> contacts = [
			SELECT
				id,
				EngGrid_Recency_Score__c,
				EngGrid_Frequency_Score__c,
				EngGrid_Monetary_Score__c,
				EngGrid_RFM_Segment__c,
				(
					SELECT Id, cpm__Amount__c, cpm__Collection_Date__c
					FROM cpm__Payments__r
					WHERE cpm__Collection_Date__c >= :collDate AND cpm__Installment__r.cpm__Status__c = 'Collected' AND cpm__Installment__r.RecordTypeId = :recordTypeReceivable
					ORDER BY cpm__Collection_Date__c DESC
				)
			FROM Contact
			WHERE Id >= :startingId
			ORDER BY Id
			LIMIT :numberOfRecords
		];
		List<Contact> updatedContacts = new List<Contact>();

		for (Contact c : contacts) {
			if (c.cpm__Payments__r.size() == 0) {
				continue;
			}
			calculateScores(c);
			calculateSegment(c);
			updatedContacts.add(c);
		}
		update updatedContacts;
	}

	public void calculateScores(Contact c) {
		Integer daysSinceLastPayment = c.cpm__Payments__r[0].cpm__Collection_Date__c.daysBetween(date.today());
		Integer numberOfPayments = c.cpm__Payments__r.size();
		Double totalAmount = 0;
		c.EngGrid_Recency_Score__c = null;
		c.EngGrid_Frequency_Score__c = null;
		c.EngGrid_Monetary_Score__c = null;
		for (cpm__Payment__c p : c.cpm__Payments__r) {
			totalAmount += p.cpm__Amount__c;
		}
		for (Integer i = 0; i < recencyRanges.size(); i++) {
			if (checkIfInRange(daysSinceLastPayment, recencyRanges[i])) {
				c.EngGrid_Recency_Score__c = recencyRanges.size() - i;
			}
			if (checkIfInRange(numberOfPayments, frequencyRanges[i])) {
				c.EngGrid_Frequency_Score__c = i + 1;
			}
			if (checkIfInRange(totalAmount, monetaryRanges[i])) {
				c.EngGrid_Monetary_Score__c = monetaryRanges.size() - i;
			}
		}
	}

	public void calculateSegment(Contact c) {
		for (Engagement_Grid_Segment__mdt s : segments) {
			List<String> minRanges = s.Min_RFM_Score__c.split('-');
			List<String> maxRanges = s.Max_RFM_Score__c.split('-');
			Integer recencyMin = Integer.valueOf(minRanges[0]);
			Integer recencyMax = Integer.valueOf(maxRanges[0]);
			Integer freqMin = Integer.valueOf(minRanges[1]);
			Integer freqMax = Integer.valueOf(maxRanges[1]);
			if (c.EngGrid_Recency_Score__c >= recencyMin && c.EngGrid_Recency_Score__c <= recencyMax && c.EngGrid_Frequency_Score__c >= freqMin && c.EngGrid_Frequency_Score__c <= freqMax) {
				c.EngGrid_RFM_Segment__c = s.Label;
			}
		}
	}

	global static Range extractRangeFromString(String s) {
		if (s.contains('-')) {
			String[] parts = s.split('-');
			return new Range(Integer.valueOf(parts[0]), Integer.valueOf(parts[1]));
		} else if (s.contains('+')) {
			String[] parts = s.split('\\+');
			return new Range(Integer.valueOf(parts[0]), -1);
		} else {
			return new Range(Integer.valueOf(s), Integer.valueOf(s));
		}
	}

	global class Range {
		global Range(Integer min, Integer max) {
			this.min = min;
			this.max = max;
		}
		global Integer min;
		global Integer max;
	}

	global static Boolean checkIfInRange(Double value, Range range) {
		if (range.max == -1) {
			return value >= range.min;
		} else {
			return value >= range.min && value <= range.max;
		}
	}
}