trigger Agreement on Agreement__c (after update ,before update) {
	AgreementTriggerHandler handler = new AgreementTriggerHandler();
	
    //if(trigger.isAfter && trigger.isInsert){
    //    handler.AfterInsert(Trigger.new);
    //}
    
    if(trigger.isAfter && trigger.isUpdate){
        handler.AfterUpdate(Trigger.new,Trigger.old);
    }
    
    /*if(trigger.isBefore && trigger.isUpdate){
        handler.BeforeUpdate(Trigger.new,Trigger.old);
    }*/
}