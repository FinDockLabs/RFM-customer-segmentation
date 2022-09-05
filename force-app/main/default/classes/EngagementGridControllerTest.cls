@isTest
public with sharing class EngagementGridControllerTest {
	@TestSetup
	static void setup() {
		List<Engagement_Grid_Segment__mdt> segments = EngagementGridController.getSegments();
		List<Contact> contacts = new List<Contact>();
		String recordTypeReceivable = [SELECT Id FROM RecordType WHERE Name = 'Receivable' AND sObjectType = 'cpm__Installment__c'][0].Id;
		for (Engagement_Grid_Segment__mdt s : segments) {
			Integer count = Integer.valueof(Math.random() * 20);

			List<String> min = s.Min_RFM_Score__c.split('-');

			for (Integer i = 0; i < count; i++) {
				contacts.add(
					new Contact(
						LastName = s.MasterLabel + i,
						Recency_Score__c = Integer.valueOf(min[0]),
						Frequency_Score__c = Integer.valueOf(min[1]),
						RFM_Segment__c = s.MasterLabel,
						Monetary_Score__c = Integer.valueOf(min[2])
					)
				);
			}
		}
		insert contacts;

		List<cpm__Installment__c> installments = new List<cpm__Installment__c>();

		for (Contact c : contacts) {
			installments.add(new cpm__Installment__c(cpm__Contact__c = c.Id, cpm__Amount__c = 5, cpm__Status__c = 'Collected', RecordTypeId = recordTypeReceivable));
		}

		insert installments;

		List<cpm__Payment__c> payments = new List<cpm__Payment__c>();

		for (cpm__Installment__c i : installments) {
			Date randDate = date.today().addDays((Math.random() * 380).intValue() * -1);
			payments.add(new cpm__Payment__c(cpm__Contact__c = i.cpm__Contact__c, cpm__Amount__c = 5, cpm__Collection_Date__c = randDate, cpm__Installment__c = i.Id));
		}

		insert payments;
	}

	@isTest
	static void getJobProgressTest() {
		test.startTest();
		Id jobId = EngagementGridController.recalculateRFM();

		Map<String, Integer> progress = EngagementGridController.getJobProgress(jobId);

		test.stopTest();

		system.assertEquals(progress.get('total'), [SELECT COUNT() FROM contact]);
	}

	@isTest
	static void getStatsTest() {
		test.startTest();
		Map<String, Object> stats = EngagementGridController.getStats();
		List<Engagement_Grid_Segment__mdt> segments = EngagementGridController.getSegments();
		test.stopTest();

		system.debug(stats);
		for (Engagement_Grid_Segment__mdt s : segments) {
			List<String> min = s.Min_RFM_Score__c.split('-');
			List<String> max = s.Max_RFM_Score__c.split('-');
			system.assertEquals(
				stats.get(s.MasterLabel),
				[
					SELECT COUNT()
					FROM contact
					WHERE
						Recency_Score__c >= :Integer.valueOf(min[0])
						AND Recency_Score__c <= :Integer.valueOf(max[0])
						AND Frequency_Score__c >= :Integer.valueOf(min[1])
						AND Frequency_Score__c <= :Integer.valueOf(max[1])
				]
			);
		}
	}
}