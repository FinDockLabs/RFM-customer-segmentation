@isTest
public with sharing class CalculateRFMJobTest {
	@testSetup
	public static void setup() {
		List<Contact> contacts = new List<Contact>();
		for (Integer i = 0; i < 50; i++) {
			Contact c = new Contact(LastName = 'John ' + i);
			contacts.add(c);
		}
		insert contacts;

		cpm__Installment__c[] installments = new List<cpm__Installment__c>();
		cpm__Payment__c[] payments = new List<cpm__Payment__c>();

		for (Contact c : contacts) {
			cpm__Installment__c inst = new cpm__Installment__c(cpm__Amount__c = Double.valueof(Math.random() * 100), cpm__Status__c = 'Collected', cpm__Contact__c = c.Id);
			installments.add(inst);
		}
		insert installments;

		for (cpm__Installment__c i : installments) {
			Date randDate = date.today().addDays((Math.random() * 380).intValue() * -1);
			cpm__Payment__c payment = new cpm__Payment__c(
				cpm__Amount__c = i.cpm__Amount__c,
				cpm__Collection_Date__c = randDate,
				cpm__Contact__c = i.cpm__Contact__c,
				cpm__Installment__c = i.Id
			);
			payments.add(payment);
		}
		insert payments;
	}

	@isTest
	static void extractRangeFromStringTest() {
		String rangeString = '1-3';
		CalculateRFMJob.Range range = CalculateRFMJob.extractRangeFromString(rangeString);
		System.assertEquals(range.min, 1);
		System.assertEquals(range.max, 3);

		rangeString = '365+';
		range = CalculateRFMJob.extractRangeFromString(rangeString);
		System.assertEquals(range.min, 365);
		System.assertEquals(range.max, -1);

		rangeString = '365';
		range = CalculateRFMJob.extractRangeFromString(rangeString);
		System.assertEquals(range.min, 365);
		System.assertEquals(range.max, 365);
	}

	@isTest
	static void checkIfInRangeTest() {
		String rangeString = '1-3';
		CalculateRFMJob.Range range = CalculateRFMJob.extractRangeFromString(rangeString);
		System.assertEquals(CalculateRFMJob.checkIfInRange(1, range), true);
		System.assertEquals(CalculateRFMJob.checkIfInRange(-1, range), false);
		System.assertEquals(CalculateRFMJob.checkIfInRange(4, range), false);
		System.assertEquals(CalculateRFMJob.checkIfInRange(3, range), true);
	}
}