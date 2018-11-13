/** 
 * 見積「無効」処理と見積「承認」後処理。
 */
public with sharing class MitumoriTriggerHandler {

    /** 
     * 見積更新のトリガハンドル
     */
    public void AfterUpdate(List<Estimate__c> newEstimateList , List<Estimate__c> oldEstimateList) {
    	//ループ処理に計数用
        Integer countNo = 0;
        //繰り返し、承認申請の見積をチェックする。
        for (Estimate__c estimate : newEstimateList) {
        	system.debug(oldEstimateList[countNo].ApprovalStatus__c);
        	system.debug(estimate.ApprovalStatus__c);
            if (estimate.QuotationStatus__c == '見積' && 
                 ((oldEstimateList[countNo].ApprovalStatus__c == '未提出' || oldEstimateList[countNo].ApprovalStatus__c == '却下') && estimate.ApprovalStatus__c == '申請提出')) {
                if (LightCheck(estimate.Id)) {//照明費用のチェック
                    estimate.addError('照明商品を選択したため、照明費を追加してください。');
                    break;
                }
            }
            countNo++;
        }
    }
    
    /**
     * 照明費用のチェックメイン処理
     */
    public boolean LightCheck(Id estimateId) {
        //商品の取得
        List<OpportunityProduct__c> oppProductList = getWonProductById(estimateId);
        //エラーの有無
        boolean result = false;
        for(OpportunityProduct__c op:oppProductList){
            //商品かつ照明取付関連
            if(op.ProductFlag__c && op.Product__r.ProductCategory__r.LightCost__c){
                result = true;
            }
        }
        for(OpportunityProduct__c op:oppProductList){
            //費用かつ照明取付関連
            if(op.SetupFeeFlag__c && op.Product__r.ProductCategory__r.LightCost__c){
                result = false;
            }
        }
        //エラーあり
        if(result){
            return true;
        } else {
            return false;
        }
    }
    
    /** 
     * 見積に属する商品を取得
     */
    public static List<OpportunityProduct__c> getWonProductById(String Id){
        String sql = 'SELECT Id,Name ';
        sql += ' ,ProductFlag__c';//商品フラグ
        sql += ' ,SetupFeeFlag__c';//費用フラグ
        sql += ' ,Product__r.ProductCategory__r.LightCost__c';//照明取付関連
        sql += '  FROM OpportunityProduct__c';
        sql += '  WHERE Estimates__c = :Id ';
        sql += ' ORDER BY LocationNo__c NULLS LAST, InstallationLocation__c NULLS LAST , SetupFeeFlag__c,SortNo__c NULLS LAST ,CreatedDate';
        
        List<OpportunityProduct__c> oppProductList = Database.query(sql);
        
        return oppProductList;
    }
    
    /** 
     * 自動APEXメソッドのパラメータ定義
     */
    public class Request {
        @InvocableVariable(required=true)
        public ID sObjId;
        @InvocableVariable(required=true)
        public String opType;
    }
    
    /** 
     * 見積の無効処理、自動
     * requests オブジェクトIDとTypeリスト
     */
    @InvocableMethod(label='disabledEstimateMain')
    public static void disabledEstimateMain(List<Request> requests) {
    	//見積情報取得
    	Estimate__c currentEstimate = [SELECT Id,Name,Opportunity__c FROM Estimate__c WHERE Id = :requests[0].sObjId];
    	//無効見積IDリスト
    	List<Id> estimateIds = new List<Id>();
        if (requests[0].opType == '手動') {//手動で見積を無効にする。
            for (Request request : requests) {
                estimateIds.add(request.sObjId);
            }
        } else if (requests[0].opType == '自動') {//見積を決定して、他の見積を自動に無効にする。
            List<Estimate__c> estimates = [SELECT Id,Name FROM Estimate__c WHERE Opportunity__c = :currentEstimate.Opportunity__c AND Id != :requests[0].sObjId];
            //見積無効処理
            for (Estimate__c estimate : estimates) {
                estimate.QuotationStatus__c = '無効';
            }
            update estimates;
            estimateIds = new List<Id>(new Map<Id, Estimate__c>(estimates).keySet());
        }
        
        //見積無効メイン処理
        if (estimateIds.size() > 0) {
            disabledEstimate(estimateIds,currentEstimate.Opportunity__c,requests[0].opType);
        }
    }
    
    /** 
     * 見積無効メイン処理
     * estimateIds 見積IDリスト
     */
    public static void disabledEstimate(List<Id> estimateIds,String oppId , String opType) {
         //無効見積の商品(HOLD不要フラグfalse)
        List<OpportunityProduct__c> products = [SELECT Id,Estimates__r.Opportunity__c
                                      	        FROM OpportunityProduct__c
                                                WHERE Estimates__c  IN :estimateIds
                                                AND Product__r.ProductCategory__r.NotNeedHold__c = false];
        
        //在库案件商品
        List<InventoryOpportunityProduct__c> inventorys = CommonUntil.getInvOppProduct(products);
        if (inventorys.size() > 0) {
            //在庫IDリスト
            List<Id> zaikoIdList = CommonUntil.getZaikoId(inventorys);
            //在庫HOLD解除
            CommonUntil.cancelInvProductHold(zaikoIdList,oppId);
        }
        if (opType == '自動') {
            //支払予定明細
            List<PaymentDetails__c> PaymentDetails = new List<PaymentDetails__c> ();
        
            List<Agreement__c> agreements = [SELECT Id,Name,(SELECT Id,Name FROM rel_PaymentDetails__r)
                                             FROM Agreement__c
                                             WHERE Estimate__c IN :estimateIds];
        
            for (Agreement__c agreement : agreements) {
                PaymentDetails.addAll(agreement.rel_PaymentDetails__r);
            }
            //更新削除
            delete agreements;
            //支払予定明細削除
            delete PaymentDetails;
            //仕入削除
            List<Purchase__c> Purchases = [SELECT Id,Name
                                           FROM Purchase__c
                                           WHERE Estimate__c IN :estimateIds];
                                           
            delete Purchases;
        }
    }
    
    /** 
     * 見積承認後、在庫-見積、配送、更新、有効期限、HOLD担当の更新
     */
    public static void updateInvProductHoldInfo(Estimate__c mitumori) {
        //見積の商品
        List<OpportunityProduct__c> products = [SELECT Id
                                      	        FROM OpportunityProduct__c
                                                WHERE Estimates__c  = :mitumori.Id];
             
        //在库案件商品
        List<InventoryOpportunityProduct__c> inventorys = CommonUntil.getInvOppProduct(products);
        if (inventorys.size() > 0) {
            //在库
            List<InventoryProduct__c> invProducts = new List<InventoryProduct__c>();
            //在庫商品の更新 HOLDになる
            for (InventoryOpportunityProduct__c invOppProduct : inventorys) {
            	if ( invOppProduct.InventoryProduct__c != null ) {
            	    InventoryProduct__c updateInvProduct = new InventoryProduct__c();
                    updateInvProduct.Id = invOppProduct.InventoryProduct__c;
                    updateInvProduct.Agreement__c = mitumori.Estimate__r[0].Id;    //更新
                    updateInvProduct.Estimate__c = mitumori.Id;    //見積
                    updateInvProduct.Haisou__c = mitumori.rel_Delivery__r[0].Id;    //配送
                    updateInvProduct.HOLDUser__c = mitumori.CreatedById;     //HOLD担当者
                    invProducts.add(updateInvProduct);
            	}
            }
            update invProducts;
        }
    }
}