/** 
 * 仕入に関するコントローラ
 */
public with sharing class PurchaseController {
    
	/**
	* 関連する仕入の更新
	* 仕入の納入日,納入時刻を更新。仕入ステータス、商品ステータスが発注済に変更
	*/
    public static void updPurchaseList(List<Purchase__c> purchaseList, String pdfType){
    	
        List<Id> purchaseIds = new List<Id>(new Map<Id, Purchase__c>(purchaseList).keySet());
        
        Map<Id,Purchase__c> purchaseMap = New Map<Id,Purchase__c>([SELECT Id,(SELECT Id,Name FROM OpporProduct__r) FROM Purchase__c WHERE Id IN :purchaseIds]);
        
        List<OpportunityProduct__c> updateOppProducts = new List<OpportunityProduct__c>();
        for (Purchase__c purchase :purchaseList) {
            if (purchase.DeliveryTime2__c != null) {
               Purchase__c purchaseNew = purchaseMap.get(purchase.Id);
               system.debug('purchaseNew.OpporProduct__r');
               system.debug(purchaseNew.OpporProduct__r);
               for (OpportunityProduct__c opportunityProduct :purchaseNew.OpporProduct__r) {
                   opportunityProduct.PurchaseYoteiDate__c = Date.newinstance(purchase.DeliveryTime2__c.year(), purchase.DeliveryTime2__c.month(), purchase.DeliveryTime2__c.day());
                   if (pdfType == 'Order') {
                      opportunityProduct.PurchaseStatus__c = '発注済';
                   }
               }
               updateOppProducts.addAll(purchaseNew.OpporProduct__r);
            }
        }
        
        system.debug('updateOppProducts');
        system.debug(updateOppProducts);
        if (updateOppProducts.size() >0) {
            update updateOppProducts;
        }
        
        if(pdfType == 'Order'){
        	//仕入の納入日,納入時刻を更新。仕入ステータス、商品ステータスが発注済に変更
    		for(Purchase__c purchase :purchaseList){
    			purchase.Status__c = '発注済';
    		}
    	}
    	update purchaseList;
    }
    
	/**
	* 関連する仕入を検索
	*/
    public static List<Purchase__c> getPurchaseById(String Id){

		String sql = 'SELECT Id,Name, Suppliers__r.Name, Suppliers__c,DeliveryTime2__c,ShippingCost__c,HaisouType__c,Status__c ,bikou__c';
    	sql += '      FROM Purchase__c ';
    	sql += '      WHERE Estimate__c = :Id ';
   		sql += '      AND (Status__c = \'未発注\' OR Status__c = \'発注済\') ';
    	sql += '      ORDER BY Suppliers__r.Name ';
		
		List<Purchase__c> purchaseList = Database.query(sql);
		System.debug('purchaseList:' + purchaseList);
		//System.debug('Suppliers__r.Name:' + purchaseList[0].Suppliers__r.Name);
		        
        return purchaseList;
    }

}