@isTest
public with sharing class ToDoCreateScheduleTest {
    // テストメソッド
    static testMethod void ToDoCreateScheduleTest() {
	    // テストデータ準備
        system.debug('ToDoCreateScheduleTest');
	    // テスト開始
	    Test.startTest();
	    
	    createData();
	    
	    //契約作成
        Agreement__c agreement = TestDataFactory.getAgreements()[0];
        
        agreement.LeaseEnd__c = Date.today();
        
        update agreement;
	
	    // Apexをスケジュールに登録
	    String jobId = System.schedule('TestScheduledApex',  '0 0 * * * ?', new ToDoCreateSchedule());
	
	    // テスト終了（登録したスケジュールが実施される）
	    Test.stopTest();

	    // テストデータの確認
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}