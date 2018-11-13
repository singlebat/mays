/** 
 * 商品のトリガ、作成、更新
 */
public class OpportunityProductTriggerHandler {
	
    /** 
     * 商品が存在していない仕入を削除
     */ 
    public void deleteEmptyPurchase(List<OpportunityProduct__c> newOppProductList) {
    	Id estimateId = newOppProductList[0].Estimates__c;
    	System.debug('deleteEmptyPurchase estimateId:' + estimateId);
    	
    	//見積に関連する仕入を検索
		List<Purchase__c> purchaseList = [SELECT Id,Name, 
								(SELECT ID, Name from OpporProduct__r)
    	                        FROM Purchase__c
    	                        WHERE Estimate__c = :estimateId];
    	                        
    	List<Purchase__c> delPurchaseList = new List<Purchase__c>();
		for (Purchase__c purchase : purchaseList) {
			if(purchase.OpporProduct__r.size() == 0){
				System.debug('deleteEmptyPurchase purchaseId:' + purchase.Id);
				delPurchaseList.add(purchase);
			}
		}		
    	delete delPurchaseList;
    } 
    
    
    /** 
     * 仕入商品作成、または更新された場合、仕入先に紐付け処理
     */ 
	public void linktoShiresaki(List<OpportunityProduct__c> newOppProductList, List<OpportunityProduct__c> oldOppProductList) {
		Id estimateId = newOppProductList[0].Estimates__c;
		Id agreementId = newOppProductList[0].Contract__c;
		System.debug('OpportunityProductTriggerHandler linktoShiresaki estimateId:' + estimateId);
		System.debug('newOppProductList:' + newOppProductList);
		System.debug('oldOppProductList:' + oldOppProductList);
		List<OpportunityProduct__c> oppProductList = new List<OpportunityProduct__c>();
		Integer cnt = 0;
		for (OpportunityProduct__c oppProduct : newOppProductList) {
			//仕入商品 かつ　仕入先が変わる場合のみ 且設置費用以外の場合
			if(oppProduct.ProductType__c =='仕入品' && oppProduct.UpdateCnt__c == 0
			     && ((oldOppProductList == null || oppProduct.Vendor__c != oldOppProductList[cnt].Vendor__c) 
			            || (oldOppProductList == null || oppProduct.HaisouType__c != oldOppProductList[cnt].HaisouType__c))
			     && oppProduct.SetupFeeFlag__c == false && oppProduct.KENSpecialDiscountFlag__c == false && oppProduct.DiscountFlag__c == false){
				oppProductList.add(oppProduct);
			}
			cnt++;
		}
		System.debug('oppProductList:' + oppProductList);

		//仕入商品 かつ　仕入先が変わるものがない場合、処理終了　
		if(oppProductList.size() == 0){
			return;
		}
				
		//見積に関連する仕入を検索
		List<Purchase__c> purchaseList = [SELECT Id,Name, Suppliers__c,HaisouType__c
    	                        FROM Purchase__c
    	                        WHERE Estimate__c = :estimateId];
		System.debug('purchaseList:' + purchaseList);
		
    	//直送仕入マップ
		Map<Id, Purchase__c> deliveryPurchaseMap = new Map<Id, Purchase__c>();
		//入庫仕入マップ
		Map<Id, Purchase__c> storingPurchaseMap = new Map<Id, Purchase__c>();
    	for (Purchase__c purchase : purchaseList) {
    		if (purchase.HaisouType__c == '顧客直送') {
    		    deliveryPurchaseMap.put(purchase.Suppliers__c, purchase);
    		} else if (purchase.HaisouType__c == '入庫') {
    		    storingPurchaseMap.put(purchase.Suppliers__c, purchase);
    		}
    	}
		
		//新規仕入リスト
		List<Purchase__c> newPurchaseList = new List<Purchase__c>();
		
		//メイズ自社情報を検索する。
		Account mays = [SELECT Id FROM Account WHERE SelfCmpFlag__c = true limit 1];
		
		//商品の仕入を作成
		for (OpportunityProduct__c oppProduct : oppProductList) {
			//仕入と直送はを分けて作成する。
			if (oppProduct.HaisouType__c == '顧客直送') {
			    if (!deliveryPurchaseMap.containsKey(oppProduct.Vendor__c)) {//商品の仕入先が存在しない場合、仕入を新規作成
			    	Purchase__c newPurchase = new Purchase__c();
				    newPurchase.Suppliers__c = oppProduct.Vendor__c;
				    newPurchase.Estimate__c = estimateId;
				    newPurchase.SelfCmp__c = mays.Id;
				    newPurchase.HaisouType__c = '顧客直送';
				    newPurchaseList.add(newPurchase);
			        deliveryPurchaseMap.put(oppProduct.Vendor__c, newPurchase);
			    }
			} else if (oppProduct.HaisouType__c == '入庫') {
			    if (!storingPurchaseMap.containsKey(oppProduct.Vendor__c)) {//商品の仕入先が存在しない場合、仕入を新規作成
			    	Purchase__c newPurchase = new Purchase__c();
				    newPurchase.Suppliers__c = oppProduct.Vendor__c;
				    newPurchase.Estimate__c = estimateId;
				    newPurchase.SelfCmp__c = mays.Id;
				    newPurchase.HaisouType__c = '入庫';
				    newPurchaseList.add(newPurchase);
			        storingPurchaseMap.put(oppProduct.Vendor__c, newPurchase);
			    }
			}
		}
		System.debug('newPurchaseList:' + newPurchaseList);
		
		if ( newPurchaseList.size() > 0 ) {
			insert newPurchaseList;
		}
		
		//仕入商品の仕入を更新
		List<OpportunityProduct__c> updOppProductList = new List<OpportunityProduct__c>();

		for (OpportunityProduct__c oppProduct : oppProductList) {
			OpportunityProduct__c updOppProduct = new OpportunityProduct__c(Id = oppProduct.Id);
			//商品の仕入を更新
			if (oppProduct.HaisouType__c == '顧客直送') {
			    updOppProduct.Purchase__c = deliveryPurchaseMap.get(oppProduct.Vendor__c).Id;
			} else if (oppProduct.HaisouType__c == '入庫') {
			    updOppProduct.Purchase__c = storingPurchaseMap.get(oppProduct.Vendor__c).Id;
			}
			updOppProductList.add(updOppProduct);
		}
		
		System.debug('updOppProductList:' + updOppProductList);		
		if ( updOppProductList.size() > 0 ) {
			update updOppProductList;
		}		
	}

    /** 
     * 1.商品のステータスは「発注済」に変更すれば、在庫と在庫案件商品の作成
     * 2.商品のステータスは「削除」に変更すれば、在庫商品の返却予定
     * 3.商品のステータスは「買取」に変更すれば、在庫商品の販売
     */ 
    public void AfterUpdate(Map<ID, OpportunityProduct__c> newMap , List<OpportunityProduct__c> newOppProductList,List<OpportunityProduct__c> oldOppProductList) {
        
    	//発注対象商品リスト
    	List<OpportunityProduct__c> targetOppProducts = new List<OpportunityProduct__c>();
    	//下代変更商品リスト
    	List<OpportunityProduct__c> salesCostOppProducts = new List<OpportunityProduct__c>();
    	
    	//ループ処理に計数用
    	Integer countNo = 0;
    	
    	Estimate__c estimate = [SELECT Id,Name ,Opportunity__c,CreatedById,ExpirationDate__c,(SELECT Id,Name FROM Estimate__r)
    	                        FROM Estimate__c
    	                        WHERE Id = :newOppProductList[0].Estimates__c];
    	
        for (OpportunityProduct__c oppProduct : newOppProductList) {
        	//下代変更商品の抽出
            if (oppProduct.SalesCost__c != oldOppProductList[countNo].SalesCost__c) {
                salesCostOppProducts.add(oppProduct);
            }
        	//発注対象商品の抽出
            if (oppProduct.PurchaseStatus__c == '発注済' 
                    && (oldOppProductList[countNo].PurchaseStatus__c == '未発注')) {
                targetOppProducts.add(oppProduct);
            }
            countNo ++ ;
        }
        //下代変更対象商品より、在庫の下代を入る
        if (salesCostOppProducts.size() > 0) {
            updateInvProducts(salesCostOppProducts,'下代変更');
        }
        //発注対象商品より、在庫と在庫案件商品の作成
        if (targetOppProducts.size() > 0) {
            updateInvProducts(targetOppProducts,'発注済');
        }
    }
   
    /** 
     * 発注により、在庫案件商品を「発注済」に更新 且 在庫商品を作成
     */ 
    public static void createProducts(List<OpportunityProduct__c> targetOppProducts,Estimate__c estimate , Map<ID, OpportunityProduct__c> newMap) {
    	//新規在庫リスト
    	List<InventoryProduct__c> newInvProductList = new List<InventoryProduct__c>();
        //在库案件商品
        List<InventoryOpportunityProduct__c> inventorys = CommonUntil.getInvOppProduct(targetOppProducts);
        //在庫商品を作成
        for (InventoryOpportunityProduct__c invOppProduct : inventorys) {
            newInvProductList.add(createInvProductMain(newMap.get(invOppProduct.OpportunityProduct__c),estimate,invOppProduct.Agreement__c));
        }
        insert newInvProductList;
        system.debug(newInvProductList);
        
        //在庫案件商品を在庫商品と紐づけ
        for (Integer i = 0 ; i <  inventorys.size() ; i++) {
            inventorys[i].InventoryProduct__c = newInvProductList[i].Id;   //在庫ID
        }
        //在庫案件商品を更新
        update inventorys;
    }
    
    /** 
     * 在庫商品の作成メイン処理
     */ 
    public static InventoryProduct__c createInvProductMain(OpportunityProduct__c oppProduct,Estimate__c estimate ,Id agreementId) {
        InventoryProduct__c invProduct = new InventoryProduct__c();
        if (oppProduct.PurchaseStatus__c == '発注済') {
            invProduct.CurrentStatus__c = '発注済';             //現状区分
        } else {
            invProduct.CurrentStatus__c = null;                 //現状区分
        }
        
        if (oppProduct.HaisouType__c == '入庫') {
            invProduct.CurrentStatusAuxiliary__c = null;        //現状補助区分
        } else if (oppProduct.HaisouType__c == '顧客直送') {
            invProduct.CurrentStatusAuxiliary__c = '直送';      //現状補助区分
        }
        
        invProduct.OtherProductName__c = oppProduct.Name;       //商品名
        invProduct.ProductMaster__c = oppProduct.Product__c;    //商品マスタ
        invProduct.SetNo__c =  oppProduct.SetNo__c;             //セット番号
        invProduct.Rank__c = oppProduct.Rank__c;                //ランク
        invProduct.InstallationLocation__c = oppProduct.InstallationLocation__c;    //設置場所
        invProduct.ProductPrice__c = oppProduct.MakerPrice__c;  //商品定価
        invProduct.SalesCost__c = oppProduct.SalesCost__c;      //下代
        invProduct.ModelNumber__c = oppProduct.ModelNumber__c;  //型番
        invProduct.Width__c = oppProduct.Width__c;              //幅
        invProduct.Height__c = oppProduct.Height__c;            //高さ
        invProduct.Depth__c = oppProduct.Depth__c;              //奥行
        invProduct.Height2__c = oppProduct.Height2__c;          //高さⅡ
        invProduct.Diameter__c = oppProduct.Diameter__c;        //直径
        invProduct.Accessories__c = oppProduct.Accessories__c;          //付属品1
        invProduct.AccessorieMod1__c = oppProduct.AccessorieMod1__c;    //付属品1型番
        invProduct.AccessorieSp1__c = oppProduct.AccessorieSp1__c;      //付属品1仕様
        invProduct.AccessorieNum1__c = oppProduct.AccessorieNum1__c;    //付属品1数量
        invProduct.AccessorieSize1__c = oppProduct.AccessorieSize1__c;  //付属品1サイズ
        invProduct.Accessories2__c = oppProduct.Accessories2__c;        //付属品2
        invProduct.AccessorieMod2__c = oppProduct.AccessorieMod2__c;    //付属品2型番
        invProduct.AccessorieSp2__c = oppProduct.AccessorieSp2__c;      //付属品2仕様
        invProduct.AccessorieNum2__c = oppProduct.AccessorieNum2__c;    //付属品2数量
        invProduct.AccessorieSize2__c = oppProduct.AccessorieSize2__c;  //付属品2サイズ
        invProduct.Accessories3__c = oppProduct.Accessories3__c;        //付属品3
        invProduct.AccessorieMod3__c = oppProduct.AccessorieMod3__c;    //付属品3型番
        invProduct.AccessorieSp3__c = oppProduct.AccessorieSp3__c;      //付属品3仕様
        invProduct.AccessorieNum3__c = oppProduct.AccessorieNum3__c;    //付属品3数量
        invProduct.AccessorieSize3__c = oppProduct.AccessorieSize3__c;  //付属品3サイズ
        invProduct.Specification1__c = oppProduct.Specification1__c;    //仕様1
        invProduct.Specification2__c = oppProduct.Specification2__c;    //仕様2
        invProduct.Specification3__c = oppProduct.Specification3__c;    //仕様3
        invProduct.Specification4__c = oppProduct.Specification4__c;    //仕様4
        invProduct.Specification5__c = oppProduct.Specification5__c;    //仕様5
        invProduct.Specification6__c = oppProduct.Specification6__c;    //仕様6
        invProduct.Specification7__c = oppProduct.Specification7__c;    //仕様7
        invProduct.Specification8__c = oppProduct.Specification8__c;    //仕様8
        invProduct.Haisou__c = oppProduct.Delivery__c;       //配送
        invProduct.Estimate__c = estimate.Id;                //見積
        invProduct.Oppotunity__c = estimate.Opportunity__c;  //案件
        invProduct.HOLDUser__c = estimate.CreatedById;       //HOLD担当者
        invProduct.HOLD__c = true;                           //HOLD区分
        invProduct.Purchase__c = oppProduct.Purchase__c;     //仕入
        invProduct.Agreement__c = agreementId;               //契約
        return invProduct;
    }
    
    
    /** 
     * 在庫商品の発注済
     * 在庫商品の下代を変更
     */ 
    public static void updateInvProducts(List<OpportunityProduct__c> oppProducts,String typeOption) {
    	//在庫リスト
    	List<InventoryProduct__c> updateInvProducts = new List<InventoryProduct__c>();
        //在库案件商品
        List<InventoryOpportunityProduct__c> inventorys = CommonUntil.getInvOppProduct(oppProducts);
        for (InventoryOpportunityProduct__c invOppProduct : inventorys ) {
            if (typeOption == '下代変更') {
                if ( invOppProduct.InventoryProduct__c != null) {
                    InventoryProduct__c invProduct = new InventoryProduct__c();
                    invProduct.Id = invOppProduct.InventoryProduct__c;
                    invProduct.SalesCost__c = invOppProduct.OpportunityProduct__r.SalesCost__c;
                    updateInvProducts.add(invProduct);
                }
            } else if (typeOption == '発注済') {
                if ( invOppProduct.InventoryProduct__c != null) {
                    InventoryProduct__c invProduct = new InventoryProduct__c();
                    invProduct.Id = invOppProduct.InventoryProduct__c;
                    invProduct.CurrentStatus__c = '発注済';    //在庫商品は「発注済」に更新
                    updateInvProducts.add(invProduct);
                }
                invOppProduct.Status__c = '発注済';    //在庫案件商品は「発注済」に更新
            }
        }
        if (typeOption == '発注済') {
            update inventorys;
        }
        update updateInvProducts;
    }
}