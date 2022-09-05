@isTest
public with sharing class ContactRFMScoreDisplayControllerTest {
	@TestSetup
	static void setup() {
		String recordTypeReceivable = [SELECT Id FROM RecordType WHERE Name = 'Receivable' AND sObjectType = 'cpm__Installment__c'][0].Id;
		Contact c = new Contact(lastName = 'Test Contact');
		List<cpm__Installment__c> installments = new List<cpm__Installment__c>();
		insert c;

		for (Integer i = 0; i < 3; i++) {
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
	static void calculateRFMSingleContactTest() {
		test.startTest();
		for (Contact c : [SELECT Id FROM Contact]) {
			Map<String, Object> details = ContactRFMScoreDisplayController.calculateRFMSingleContact(c.Id);

			system.assertEquals(Integer.valueOf(details.get('m_detail')), 15);
			system.assertEquals(Integer.valueOf(details.get('f_detail')), 3);
			system.assertEquals(details.get('status'), 'success');
		}

		test.stopTest();
	}
}