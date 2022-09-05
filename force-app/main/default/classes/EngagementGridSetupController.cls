public with sharing class EngagementGridSetupController {
	@AuraEnabled
	public static List<Engagement_Grid_Segment__mdt> getSegments() {
		return [SELECT Id, DeveloperName, MasterLabel, Colour__c, Max_RFM_Score__c, Min_RFM_Score__c FROM Engagement_Grid_Segment__mdt];
	}

	@AuraEnabled
	public static Boolean setRecalculationDue() {
		try {
			List<Engagement_Grid_Setting__mdt> settings = [SELECT Id, DeveloperName, MasterLabel, Re_Calculation_Due__c FROM Engagement_Grid_Setting__mdt LIMIT 1];
			List<Engagement_Grid_Setting__mdt> updated = new List<Engagement_Grid_Setting__mdt>();
			for (Engagement_Grid_Setting__mdt s : settings) {
				s.Re_Calculation_Due__c = true;
				updated.add(s);
			}
			MetaDataUtility.upsertMetadata(updated);
			return true;
		} catch (Exception e) {
			return false;
		}
	}

	@AuraEnabled
	public static void setRecalculationNotDue() {
		List<Engagement_Grid_Setting__mdt> settings = [SELECT Id, DeveloperName, MasterLabel, Re_Calculation_Due__c FROM Engagement_Grid_Setting__mdt LIMIT 1];
		List<Engagement_Grid_Setting__mdt> updated = new List<Engagement_Grid_Setting__mdt>();
		for (Engagement_Grid_Setting__mdt s : settings) {
			s.Re_Calculation_Due__c = false;
			updated.add(s);
		}
		MetaDataUtility.upsertMetadata(updated);
	}

	public static List<Engagement_Grid_Setting__mdt> setDefaultSettings() {
		List<Engagement_Grid_Setting__mdt> s = new List<Engagement_Grid_Setting__mdt>();
		Engagement_Grid_Setting__mdt settings = new Engagement_Grid_Setting__mdt();
		settings.put('Re_Calculation_Due__c', true);
		settings.put('MasterLabel', 'Main');
		settings.put('DeveloperName', 'Main');
		List<Report> reports = [SELECT Id FROM Report WHERE DeveloperName = 'Engagement_Grid_Contacts_in_Segment_Mis' LIMIT 1];
		if (reports.size() > 0) {
			settings.put('Report_Id__c', reports[0].Id);
		}
		s.add(settings);
		EngagementGridSetupController.saveMetadata(s);
		return s;
	}

	@AuraEnabled
	public static Engagement_Grid_Setting__mdt getSettings() {
		List<Engagement_Grid_Setting__mdt> s = [
			SELECT Id, DeveloperName, MasterLabel, Report_Id__c, Date_Range_Start__c, Re_Calculation_Due__c, Y_Axis__c
			FROM Engagement_Grid_Setting__mdt
			LIMIT 1
		];
		if (s.size() == 0 || s[0].Report_Id__c == null) {
			s = EngagementGridSetupController.setDefaultSettings();
		}
		return s[0];
	}

	@AuraEnabled
	public static String saveMetadata(List<sObject> metadata) {
		String deploymentID = MetaDataUtility.upsertMetadata(metadata);
		return deploymentID;
	}

	@AuraEnabled
	public static void runFirstJob() {
		CalculateRFMQueueable ct = new CalculateRFMQueueable();
		id createdJobId = ct.start();
		System.debug('Starting RFM re-calculation job with id ' + createdJobId);
	}

	@AuraEnabled
	public static cpm__Heartbeat__c[] getCurrentHeartbeat(String className) {
		cpm__Heartbeat__c[] hb = [SELECT Id, Name, cpm__Class__c, cpm__Starting_Hour__c, cpm__Order__c FROM cpm__Heartbeat__c WHERE cpm__Class__c = :className LIMIT 1];
		return hb;
	}

	@AuraEnabled
	public static Boolean scheduleHeartbeat(String className, Integer startingHour) {
		try {
			cpm__Heartbeat__c hb = new cpm__Heartbeat__c();
			hb.Name = className;
			hb.cpm__Class__c = className;
			hb.cpm__Order__c = 99;
			hb.cpm__Starting_Hour__c = startingHour;
			upsert hb;
			return true;
		} catch (Exception e) {
			System.debug(e.getMessage());
			return false;
		}
	}

	@AuraEnabled
	public static Boolean deleteHeartbeat(String className) {
		try {
			cpm__Heartbeat__c hb = [SELECT Id FROM cpm__Heartbeat__c WHERE cpm__Class__c = :className LIMIT 1];
			if (hb != null) {
				delete hb;
			}
			return true;
		} catch (Exception e) {
			System.debug(e.getMessage());
			return false;
		}
	}
}