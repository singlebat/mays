trigger Billed on Billed__c (before delete) {
	BilledTriggerHandler handler = new BilledTriggerHandler();
    if(Trigger.isDelete){
        String error=handler.beforeDelete(Trigger.old);
        if(error!=null){
        	Trigger.old[0].addError(error);
        }
    }
    
}