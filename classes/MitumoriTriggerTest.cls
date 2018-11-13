@isTest
public with sharing class MitumoriTriggerTest {
    static testMethod void testMitumoriTrigger() {
        Test.startTest();
        createData();

        Estimate__c estimate = TestDataFactory.getLeaseEstimate()[0];
		Estimate__c estimateCopy= new Estimate__c();
		estimateCopy.Opportunity__c=estimate.Opportunity__c;
		estimateCopy.RecordtypeId= estimate.RecordtypeId;
        estimateCopy.LeaseTerm__c= estimate.LeaseTerm__c; //リース契約期間
        estimateCopy.QuotationStatus__c= estimate.QuotationStatus__c ; //見積ステータス
        estimateCopy.ApprovalStatus__c= estimate.ApprovalStatus__c ; //承認状態
        estimateCopy.QuotationType__c= estimate.QuotationType__c ; //見積タイプ
        estimateCopy.EstimatedDate__c= estimate.EstimatedDate__c; //見積日
        estimateCopy.LeaseStart__c= estimate.LeaseStart__c;//LeaseStart__c
        estimateCopy.LeaseEnd__c= estimate.LeaseEnd__c;//LeaseStart__c
        estimateCopy.SyokaiLeaseMonthCnt__c= estimate.SyokaiLeaseMonthCnt__c;//初回ﾘｰｽ月数（ヶ月）
        estimateCopy.MonthlyLeaseRate__c= estimate.MonthlyLeaseRate__c;//月額リース料率
        estimateCopy.Seikyusaki__c= estimate.Seikyusaki__c;//請求先
		insert estimateCopy;
		
		//照明費用のチェックメイン処理
		estimateCopy.ApprovalStatus__c = '申請提出';
		update estimateCopy;
		
		MitumoriTriggerHandler.Request re= new MitumoriTriggerHandler.Request();
		re.sObjId=estimate.Id;
		re.opType='自動';
		List<MitumoriTriggerHandler.Request> requests =new List<MitumoriTriggerHandler.Request>();
		requests.add(re);
        MitumoriTriggerHandler.disabledEstimateMain(requests);
        estimate = CommonUntil.getEstimateById(estimate.Id);
        MitumoriTriggerHandler.updateInvProductHoldInfo(estimate);
        Test.stopTest();
    }
   
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}