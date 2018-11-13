/** 
 * 見積詳細レコード画面において、商品一覧コンポーネントに向けコントローラ
 */
public class ProductEditListController {
	
	@AuraEnabled
    public static InitObj getInitInfo(String Id,String sObjectName){
        InitObj initObj = new InitObj();
        if (sObjectName == 'Estimate__c') {
            initObj.estimate = CommonUntil.getEstimateById(Id);
        } else if (sObjectName == 'Agreement__c') {
            initObj.agreement = getContractById(Id);
        }
        initObj.options = getInstallationLocations();
        initObj.oppProducts = getWonProductById(Id,sObjectName);
        initObj.salesOppId = [SELECT Id,Name FROM RecordType WHERE Name = '販売' AND SobjectType = 'OpportunityProduct__c'][0].Id;
        return initObj;
    }
    
    @AuraEnabled
    public static Agreement__c getContractById(String Id){
        return [SELECT Id,Name,Estimate__r.RecordTypeId FROM Agreement__c WHERE Id = :Id];
    }

	@AuraEnabled
    public static List<OpportunityProduct> getWonProductById(String Id,String sObjectName){
        String sql = 'SELECT Id,Name,Vendor__r.Name,ProductType__c,Rank__c,Maker__c,Quantity__c  ';
        sql += ' ,SortNo__c';
        sql += ' ,MonthlyLeaseRate__c,InstallationLocation__r.Name';
        sql += ' ,SetupFeeFlag__c,MakerPrice__c,UnitPriceLease__c,AmountPercentLease__c,PurchaseStatus__c';
        sql += ' ,HaisouType__c,AmountPercentSelling__c,MonthlyLeaseFee__c';
        sql += ' ,Delivery__r.DeliveryStatus__c,Delivery__r.DeliveryPrepareDay__c,CurrentStatus__c';
        sql += ' ,SellingRate__c,SalesCost__c,PurchaseRate__c,InventoryProductNo__c,InventoryProductID__c,ToriyokiFlag__c,Estimates__c';
        sql += ' ,KENSpecialDiscountFlag__c,DiscountFlag__c';
        sql += '  FROM OpportunityProduct__c';
        if (sObjectName == 'Estimate__c') {
            sql += '  WHERE Estimates__c = :Id ';
            sql += '  AND UpdateCnt__c = 0';
        } else if (sObjectName == 'Agreement__c') {
            sql += '  WHERE Contract__c = :Id ';
        } else {
            sql += '  WHERE Estimates__c = :Id ';
            sql += '  AND UpdateCnt__c = 0';
        }
        sql += ' ORDER BY LocationNo__c NULLS LAST, InstallationLocation__c NULLS LAST , SetupFeeFlag__c,SortNo__c NULLS LAST ,CreatedDate';
        
        List<OpportunityProduct__c> oppProductList = Database.query(sql);
        system.debug(oppProductList);
        
        List<OpportunityProduct> productList = new List<OpportunityProduct>();
        //選択フラグ付き処理
        for (OpportunityProduct__c oppProduct : oppProductList) {
        	OpportunityProduct product = new OpportunityProduct();
            product.selectedFlg = false;
            product.oppProduct = oppProduct;
            productList.add(product);
        }
        return productList;
    }

    @AuraEnabled
    public static void updateWonProduct(List<OpportunityProduct__c> updateProductList){
        update updateProductList;
    }
    
    /** 
     * 画面で削除アイコンをクリックして、商品とセット商品を削除します。そして、在庫のHOLDも解除する。
     */ 
    @AuraEnabled
    public static void deletedRecordById(Id Id){
        string setNo;
        //選定商品
        OpportunityProduct__c oppPro = [SELECT Id,Name,SetNo__c,Estimates__c,Estimates__r.Opportunity__c,Product__r.ProductCategory__r.NotNeedHold__c FROM OpportunityProduct__c WHERE Id =: Id];
        
        //削除商品リスト
        List<OpportunityProduct__c> oppProDeleteList = new List<OpportunityProduct__c>();
        if (oppPro.SetNo__c != null && oppPro.SetNo__c != '') {
             oppProDeleteList = [SELECT Id FROM OpportunityProduct__c WHERE SetNo__c = :oppPro.SetNo__c and Estimates__c = :oppPro.Estimates__c];
        } else {
            oppProDeleteList.add(oppPro);
        }
        
        //在库案件商品
        List<InventoryOpportunityProduct__c> inventorys = CommonUntil.getInvOppProduct(oppProDeleteList);
        
        //在庫IDリスト
        List<Id> zaikoIdList = CommonUntil.getZaikoId(inventorys);

        if(oppProDeleteList != null && oppProDeleteList.size()>0){
            delete oppProDeleteList;
        }else{
            Database.delete(Id);
        }
        
        system.debug('inventorys');
        system.debug(inventorys);
        //在庫案件商品の削除 20180405追加
        delete inventorys;
                                                            
        //在庫HOLD解除
        if (!oppPro.Product__r.ProductCategory__r.NotNeedHold__c) {
            CommonUntil.cancelInvProductHold(zaikoIdList,oppPro.Estimates__r.Opportunity__c);
        }
    }

    @AuraEnabled
    public static RecordType[] getRecordTypeId(){
        return [SELECT Id,Name FROM RecordType WHERE (Name = 'リース' or Name = '販売') AND SobjectType = 'Estimate__c'];
    }
    
    /** 
     * 設置場所マスタデータを一括取得
     */
    @AuraEnabled
    public static List<CommonUntil.Option> getInstallationLocations(){
        List<InstallationLocation__c> installationLocations = [SELECT Id,Name 
    	                                                       FROM InstallationLocation__c
    	                                                       ORDER BY Number__c];
    	//設置場所オプションリスト
    	List<CommonUntil.Option> options = new List<CommonUntil.Option>();
    	CommonUntil.Option noneOption = new CommonUntil.Option();
    	noneOption.label = '--なし--';
        noneOption.value = '';
        options.add(noneOption);
    	for (InstallationLocation__c installationLocation : installationLocations) {
    	    CommonUntil.Option option = new CommonUntil.Option();
            option.label = installationLocation.Name;
            option.value = installationLocation.Id;
            options.add(option);
    	}
        return options;
    }
    
    /** 
     * 初期化カスタマイズOBJ
     */ 
    public class InitObj {
    	/**
         * 見積
         */
    	@AuraEnabled
        public Estimate__c estimate;
        
        /**
         * 契約
         */
    	@AuraEnabled
        public Agreement__c agreement; 
        
    	/**
         * 設置場所マスタデータ
         */
    	@AuraEnabled
        public List<CommonUntil.Option> options;
        
        /**
         * カスタマイズ商品表示リスト
         */
        @AuraEnabled
        public List<OpportunityProduct> oppProducts {get;set;}
        
        /**
         * 販売商品レコードタイプID
         */
    	@AuraEnabled
        public String salesOppId; 
    }
    
    /** 
     * 商品表示リスト
     */ 
    public class OpportunityProduct {
    	/**
         * 選択フラグ
         */
    	@AuraEnabled
        public boolean selectedFlg;
        
        /**
         * 商品オブジェクト
         */
        @AuraEnabled
        public OpportunityProduct__c oppProduct {get;set;}
    }
}