@isTest
public with sharing class EngagementGridSetupControllerTest {
	@isTest
	static void scheduleHeartbeatTest() {
		test.startTest();
		EngagementGridSetupController.scheduleHeartbeat('TestClass', 16);
		test.stopTest();

		cpm__Heartbeat__c hb = [SELECT Id, cpm__Starting_Hour__c, cpm__Class__c FROM cpm__Heartbeat__c WHERE cpm__Class__c = :'TestClass' LIMIT 1];

		system.assertEquals(hb.cpm__Starting_Hour__c, 16);
		system.assertEquals(hb.cpm__Class__c, 'TestClass');
	}

	@isTest
	static void deleteHeartbeatTest() {
		EngagementGridSetupController.scheduleHeartbeat('TestClass', 16);

		test.startTest();
		EngagementGridSetupController.deleteHeartbeat('TestClass');
		test.stopTest();

		List<cpm__Heartbeat__c> hb = [SELECT Id, cpm__Starting_Hour__c, cpm__Class__c FROM cpm__Heartbeat__c WHERE cpm__Class__c = 'TestClass'];

		system.assertEquals(hb.size(), 0);
	}

	@isTest
	static void getSettingsTest() {
		Engagement_Grid_Setting__mdt setting = EngagementGridSetupController.getSettings();
		system.AssertEquals(setting.DeveloperName, 'Main');
		System.assertEquals( EngagementGridSetupController.getSegments().size() , 7 );
	}

	@isTest
	static void setDefaultSettingsTest() {
		List<Engagement_Grid_Setting__mdt> settings = EngagementGridSetupController.setDefaultSettings();
		EngagementGridSetupController.setRecalculationDue();
		system.AssertEquals(settings.size(), 1);
		system.AssertEquals(settings[0].DeveloperName, 'Main');
		system.AssertEquals(settings[0].Re_Calculation_Due__c, true);
		EngagementGridSetupController.setRecalculationNotDue();
	}
}