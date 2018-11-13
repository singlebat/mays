trigger OpportunityProduct on OpportunityProduct__c (after insert, after update) {
    System.debug('OpportunityProduct Trigger start ');
    OpportunityProductTriggerHandler handler = new OpportunityProductTriggerHandler();
	
    if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
    	try{
    		//1. 商品のステータスは「発注済」に変更すれば、在庫と在庫案件商品の作成
    		if(trigger.isUpdate){
        		handler.AfterUpdate(trigger.newMap,Trigger.new,Trigger.old);
    		}
    		//2. 仕入商品作成、または更新された場合、仕入先に紐付け処理
    		handler.linktoShiresaki(Trigger.new,Trigger.old);
        	//商品が存在していない仕入を削除
        	handler.deleteEmptyPurchase(Trigger.new);
        }Catch(Exception e){
    		Trigger.new[0].addError('エラーが発生しました：[' + e + ']');
    	}
    }
    System.debug('OpportunityProduct Trigger end ');
}