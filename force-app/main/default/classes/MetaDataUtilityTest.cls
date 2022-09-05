@isTest
public with sharing class MetaDataUtilityTest {
	@isTest
	static void upsertMetadataTest() {
		Engagement_Grid_Setting__mdt md = new Engagement_Grid_Setting__mdt();
		md.DeveloperName = 'test';
		md.Date_Range_Start__c = system.today();

		String jobId = MetaDataUtility.upsertMetadata(md);

		system.assertEquals(jobId, 'TestJobId');
	}
}