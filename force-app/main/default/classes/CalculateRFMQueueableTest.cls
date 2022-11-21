@isTest
public with sharing class CalculateRFMQueueableTest {
	@TestSetup
	static void setup() {
		CalculateRFMJobTest.setup();
	}

	@isTest
	static void CalculateRFMQueueableTest() {
		// when
		Test.startTest();
		CalculateRFMQueueable ct = new CalculateRFMQueueable();
		id createdJobId = ct.start();
		Test.stopTest();

		// then
		List<Contact> contactList = [SELECT Id FROM Contact WHERE EngGrid_RFM_Segment__c != NULL];
		System.assert(contactList.size() > 0);
	}
}