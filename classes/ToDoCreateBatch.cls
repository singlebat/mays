global with sharing class ToDoCreateBatch implements Database.Batchable<sObject>{
    //データ取得
    global Database.QueryLocator start(Database.BatchableContext BC){
    	String query = 'SELECT Id,Name,AutoOrManual__c FROM Agreement__c ';
    	query += ' WHERE LeaseEndToDoCreate__c <= TODAY';
        return Database.getQueryLocator(query);
    }
  
    //開始
    global void execute(Database.BatchableContext BC, List<Agreement__c> scopes){
    	//TODOリスト
    	List<Task> newTasks = new List<Task>();
        //バッチの処理を記述
        for (Agreement__c agreement : scopes) {
        	Task task = new Task();
        	task.WhatId = agreement.id;
            //task.WhoId = agreement.Oppotunity__r.OwnerId;//今、案件所有者の名前
            //task.priority= Object.Priority__c;
            task.status = 'In Progress';
            task.description = 'リース契約期間満了通知';
            task.Priority = 'High';
        	if (agreement.AutoOrManual__c == '自動') {
        	    task.Subject = '契約更新通知 自動';
        	} else {
        	    task.Subject = '契約更新通知 手動';
        	}
        	newTasks.add(task);
        }
        if (newTasks.size() > 0) {
            insert newTasks;
        }
    }
  
    //完了
    global void finish(Database.BatchableContext BC)
    {
        //完了後の処理があれば
    }
}