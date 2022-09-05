global with sharing class CalculateRFMQueueableBeat extends cpm.Heartbeat {
	global CalculateRFMQueueableBeat(cpm__Heartbeat__c lastBeat) {
		super(lastBeat);
	}

	global CalculateRFMQueueableBeat() {
		super(null);
	}

	global override void execute() {
		CalculateRFMQueueable job = new CalculateRFMQueueable();
		job.start();
	}
}