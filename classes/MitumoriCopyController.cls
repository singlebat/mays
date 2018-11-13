/** 
 * 見積詳細レコード画面において、「見積コピー」クイックアクションより、見積コピーコンポーネントに向けコントローラです。
 */
public class MitumoriCopyController {
	 @AuraEnabled
    public static Estimate__c getStatus(String id) {
		Estimate__c ec =[SELECT QuotationStatus__c FROM Estimate__c WHERE Id = :id];
		return ec;
    }
    
    @AuraEnabled
    public static String copy(String id, String copyType) {
        system.debug(id);
        String soql = 'SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('Estimate__c'), ',')
            + ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('Delivery__c'), ',') + ' FROM rel_Delivery__r)'
            + ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('Agreement__c'), ',') + ' FROM Estimate__r)'
            + ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('Purchase__c'), ',') + ' FROM Purchase__r)'
            + ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('OpportunityProduct__c'), ',')
            + ' FROM rel_chxq__r) FROM Estimate__c WHERE Id = :id';
            
        system.debug('soql:**'+soql);
        
        Estimate__c quote = Database.query(soql);

        //見積のコピー
        Estimate__c quoteNew = quote.clone(false, false, false, false);
        quoteNew.QuotationStatus__c = '見積';
        quoteNew.BaseEstimate__c = id;
        
        if (copyType == 'new') {//新規採番の場合
            EstimateNumber__c estimateNum = [SELECT Id,EstimateSerialNum__c FROM EstimateNumber__c FOR UPDATE];
	        estimateNum.EstimateSerialNum__c += 1;
	        update estimateNum;
	        system.debug(estimateNum.EstimateSerialNum__c);
	        quoteNew.Name = 'L' + String.valueOf((Integer)estimateNum.EstimateSerialNum__c).leftPad(4, '0') + '_00';
        } else {//枝番の場合
        	String name = quote.Name.left(6) + '%';
            List<Estimate__c> estimates = [SELECT Id,Name FROM Estimate__c WHERE Name like :name order by CreatedDate desc];
            //if (estimates.size() == 1) {
            //    quoteNew.Name = quote.Name + '_01';
            //} else {
                quoteNew.Name = estimates[0].Name.left(6) + String.valueOf(Integer.valueOf(estimates[0].Name.right(2)) + 1).leftPad(2, '0');
            //}
        }
        
        insert quoteNew;
        
        ID idNew = quoteNew.Id;
        
        system.debug(quote.rel_chxq__r); 
        
        //新規更新リスト
        List<Agreement__c> agreementNewList = new List<Agreement__c>();
        //更新のコピー
        if (!quote.Estimate__r.isEmpty()) {
            for (Agreement__c agreement : quote.Estimate__r) {
                Agreement__c agreementNew = agreement.clone(false, false, false, false);
                agreementNew.Estimate__c = idNew;
                agreementNew.Name = quoteNew.Name.left(6) + agreement.Name.right(3);
                agreementNewList.add(agreementNew);
            }
            insert agreementNewList;
        } else {
            return '';
        }
        
        //配送のコピー コピーできるの時、配送は必ず一つとする。
        Delivery__c deliveryNew = quote.rel_Delivery__r[0].clone(false, false, false, false);
        deliveryNew.Estimate__c = idNew;
        deliveryNew.Agreement__c = agreementNewList[0].Id;
        insert deliveryNew;
        
        //quoteNew.FirstAgreement__c = agreementNewList[0].Id;
        //update quoteNew;
        
        if (!quote.rel_chxq__r.isEmpty()) {
        	List<Id> oldOppProIds = new List<Id>();
        	for (OpportunityProduct__c oppPro : quote.rel_chxq__r) {
                oldOppProIds.add(oppPro.Id);
            }
            
            String soql2 = 'SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('OpportunityProduct__c'), ',')
            + ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('InventoryOpportunityProduct__c'), ',') 
            + ' FROM Rel_IHmV__r) FROM OpportunityProduct__c WHERE Id in :oldOppProIds';
            
            List<OpportunityProduct__c> oldOppProList = Database.query(soql2);
                       
            //商品のコピー
            List<OpportunityProduct__c> oppProNewList = new List<OpportunityProduct__c>();
            for (OpportunityProduct__c oppPro : oldOppProList) {
                OpportunityProduct__c oppProNew = oppPro.clone(false, false, false, false);
                oppProNew.Estimates__c = idNew;
                oppProNew.Delivery__c = deliveryNew.Id;
                oppProNew.Purchase__c = null;
                oppProNew.Contract__c = agreementNewList[0].Id;
                oppProNewList.add(oppProNew);
            }
            insert oppProNewList;
            
            //在庫案件商品のコピー
            List<InventoryOpportunityProduct__c> invOppProNewList = new List<InventoryOpportunityProduct__c>();
            Integer countNo = 0 ; 
            for (OpportunityProduct__c oppPro : oldOppProList) {
            	ID oppProIdNew = oppProNewList[countNo].Id;
                for (InventoryOpportunityProduct__c invOppPro : oppPro.Rel_IHmV__r) {
                    InventoryOpportunityProduct__c invOppProNew = invOppPro.clone(false, false, false, false);
                    invOppProNew.OpportunityProduct__c = oppProIdNew;    //商品
                    invOppProNew.Agreement__c = agreementNewList[0].Id;    //更新
                    invOppProNewList.add(invOppProNew);
                }
                countNo ++;
            }
            insert invOppProNewList;
            
            //商品、在庫案件商品、在庫商品の配送を更新
            CommonUntil.updateRelDelivery(new List<OpportunityProduct__c>(),invOppProNewList,deliveryNew.Id);
            
            //在庫見積の更新
            List<InventoryProduct__c> updateZaikoList = new List<InventoryProduct__c>();

            for(InventoryOpportunityProduct__c invOppProduct : invOppProNewList){
            	if (invOppProduct.InventoryProduct__c != null) {
            	    InventoryProduct__c invProduct = new InventoryProduct__c();
                    invProduct.Id = invOppProduct.InventoryProduct__c;
                    invProduct.Estimate__c = idNew;
                    invProduct.Agreement__c = agreementNewList[0].Id;
                    updateZaikoList.add(invProduct);
            	}
            }
            update updateZaikoList;
        }
        //新しい見積IDをリターン
        return idNew;
    }
}