@JsonAccess(serializable='always' deserializable='always')
global with sharing class CalculateRFMQueueable extends cpm.BaseJobProcessGlobal {
	global String recordTypeReceivable { get; set; }

	global CalculateRFMQueueable() {
		this.recordTypeReceivable = [SELECT Id FROM RecordType WHERE Name = 'Receivable' AND sObjectType = 'cpm__Installment__c'][0].Id;
		this.startTimeGmt = datetime.now();
		this.jobProcess = 'RFM Score Calculation';
		this.setParameters(new Map<String, Object>{ 'recordTypeReceivable' => (Object) recordTypeReceivable });
	}

	global override string getCountQuery() {
		return 'SELECT COUNT() FROM Contact';
	}

	global override string getChunkQuery() {
		return 'SELECT id FROM Contact ORDER BY Id';
	}

	global override set<String> getRequiredParameters() {
		return new Set<String>{ 'recordTypeReceivable' };
	}

	global override String toJSON() {
		return JSON.serializePretty(this, true);
	}

	global override Integer getChunkSize() {
		return 2000;
	}

	global override cpm.BaseJobGlobal getJobInstance() {
		return new CalculateRFMJob();
	}
	global override void finalizeProcess() {
		// nothing to do in finalizing process
	}
}