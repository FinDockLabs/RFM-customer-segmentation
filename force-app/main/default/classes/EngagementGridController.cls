public class EngagementGridController {
	@AuraEnabled(cacheable=true)
	public static Map<String, Object> getStats() {
		Map<String, Object> stats = new Map<String, Object>();
		Integer total = 0;

		List<Sobject> countBySegments = database.query('select count(Id) recordCount, EngGrid_RFM_Segment__c from contact where EngGrid_RFM_Segment__c != null group by EngGrid_RFM_Segment__c');

		for (Sobject segment : countBySegments) {
			stats.put(String.valueOf(segment.get('EngGrid_RFM_Segment__c')), Integer.valueOf(segment.get('recordCount')));
			stats.put(String.valueOf(segment.get('EngGrid_RFM_Segment__c')) + ' Average', 0);
			total += Integer.valueOf(segment.get('recordCount'));
		}

		// double check if we need to add empty segments
		for (Engagement_Grid_Segment__mdt s : getSegments()) {
			if (!stats.containsKey(s.MasterLabel)) {
				stats.put(s.MasterLabel, 0);
			}
		}
		stats.put('total', total);
		return stats;
	}

	@AuraEnabled
	public static List<Engagement_Grid_Segment__mdt> getSegments() {
		return [SELECT Id, DeveloperName, Colour__c, MasterLabel, Min_RFM_Score__c, Max_RFM_Score__c FROM Engagement_Grid_Segment__mdt];
	}

	@AuraEnabled
	public static List<Engagement_Grid_Range__mdt> getRanges() {
		return [SELECT Id, MasterLabel, DeveloperName, Frequency_Range__c, Monetary_Range__c, Recency_Range__c, Order__c FROM Engagement_Grid_Range__mdt ORDER BY Order__c DESC];
	}

	@AuraEnabled
	public static String getReportIdByName(String Name) {
		return [SELECT Id FROM Report WHERE DeveloperName = :Name].Id;
	}

	@AuraEnabled
	public static Id recalculateRFM() {
		CalculateRFMQueueable job = new CalculateRFMQueueable();
		id createdJobId = job.start();
		return createdJobId;
	}

	@AuraEnabled
	public static Map<String, Integer> getJobProgress(Id jobId) {
		Map<String, Integer> stats = new Map<String, Integer>();
		List<cpm__Job__c> rows = [SELECT Id, cpm__Payload__c, cpm__Status__c FROM cpm__Job__c WHERE cpm__Group_Identifier__c = :jobId];
		cpm__Job__c mainJob = [SELECT cpm__Total_Records__c FROM cpm__Job__c WHERE Id = :jobId];
		Integer total = (Integer) mainJob.cpm__Total_Records__c;
		Integer done = 0;
		Integer failed = 0;
		Integer error = 0;
		for (cpm__Job__c r : rows) {
			Map<String, Object> p = (Map<String, Object>) JSON.deserializeUntyped(r.cpm__Payload__c);
			if (r.cpm__Status__c == 'Done') {
				done += Integer.valueOf(p.get('numberOfRecords'));
			}
			if (r.cpm__Status__c == 'Failed') {
				failed += Integer.valueOf(p.get('numberOfRecords'));
			}
			if (r.cpm__Status__c == 'Error') {
				error += Integer.valueOf(p.get('numberOfRecords'));
			}
		}
		stats.put('total', total);
		stats.put('done', done);
		stats.put('failed', failed);
		stats.put('error', error);
		return stats;
	}
}