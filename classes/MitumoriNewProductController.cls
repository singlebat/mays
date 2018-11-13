/** 
 * 見積詳細レコード画面において、商品を作成するコピーコンポーネントに向けコントローラです。
 */
public class MitumoriNewProductController {
	
	/** 
     * 商品編集の場合、商品明細を取得
     * Id  商品ID
     */
    @AuraEnabled
    public static InitDetail initEdit(String productId){
        OpportunityProduct__c oppProduct = [SELECT Id,Name,
                                                   InstallationLocation__r.Name,InstallationLocation__c,
                                                   Vendor__c,Vendor__r.Name,
                                                   PurchaseRate__c,ProductType__c,Product__c
                                            FROM OpportunityProduct__c WHERE Id =: productId];

        InitDetail initDetail = new InitDetail();
        initDetail.oppProduct = oppProduct;
        
        if (oppProduct.ProductType__c == '仕入品') {//仕入品の場合、商品マスタから、画像情報を取得
        	CustomObjectProductMaster__c productMaster = [SELECT Id,PictureURL1__c,(SELECT Id FROM CombinedAttachments) FROM CustomObjectProductMaster__c WHERE Id = :oppProduct.Product__c];
            initDetail.imgIds = OppProductCreateController.getImgId(new List<Id>(new Map<Id, CombinedAttachment>(productMaster.CombinedAttachments).keySet()));    //画像ContentDocumentのID
            initDetail.pictureURL = productMaster.PictureURL1__c;
        } else if (oppProduct.ProductType__c == '在庫品') {//仕入品の場合、在庫から、画像情報を取得
            List<InventoryOpportunityProduct__c> invOppProductList = [SELECT id,InventoryProduct__r.HOLD__c,
                                                                             InventoryProduct__c
                                                     	              FROM InventoryOpportunityProduct__c
                                                                      WHERE OpportunityProduct__c  = :oppProduct.Id];
            if (invOppProductList.size() > 0) {
                InventoryProduct__c invProduct = [SELECT Id,PictureURL1__c,(SELECT Id FROM CombinedAttachments) FROM InventoryProduct__c WHERE Id = :invOppProductList[0].InventoryProduct__c];
                initDetail.imgIds = OppProductCreateController.getImgId(new List<Id>(new Map<Id, CombinedAttachment>(invProduct.CombinedAttachments).keySet()));    //画像ContentDocumentのID
                initDetail.pictureURL = invProduct.PictureURL1__c;
            }
        }
        
        return initDetail;
    }
    
    /** 
     * 商品マスタ情報を取得
     * productMasterId  商品マスタID
     */
    @AuraEnabled
    public static CustomObjectProductMaster__c getProductMasterInfo(String productMasterId){
        List<CustomObjectProductMaster__c> customObjectProductMasterList =  [SELECT Id,ListPrice__c,Name,Maker__c,ModelNumber__c,Maker__r.Name,
                                                                                    Height__c,Width__c,Depth__c,Height2__c,Diameter__c,
                                                                                    ModelNo__c,
                                                                                    ColorNo__c,Color__c,
                                                                                    WhiteHot__c,DenkyuColor__c,LED__c,RC__c,EasySet__c,OneTatch__c,
                                                                                    Volume__c,YoRyo__c,
                                                                                    Specification1__c,    //仕様1
                                                                                    Specification2__c,    //仕様2
                                                                                    Specification3__c,    //仕様3
                                                                                    Specification4__c,    //仕様4
                                                                                    Specification5__c,    //仕様5
                                                                                    Specification6__c,    //仕様6
                                                                                    Specification7__c,    //仕様7
                                                                                    Specification8__c,    //仕様8
                                                                                    Accessories__c,       //付属品名称1
                                                                                    AccessorieMod1__c,    //付属品型番1
                                                                                    AccessorieSp1__c,     //付属品仕様1
                                                                                    AccessorieNum1__c,    //付属品数量1
                                                                                    AccessorieSize1__c,   //付属品サイズ1
                                                                                    Accessories2__c,
                                                                                    AccessorieMod2__c,
                                                                                    AccessorieSp2__c,
                                                                                    AccessorieNum2__c,
                                                                                    AccessorieSize2__c,
                                                                                    Accessories3__c,
                                                                                    AccessorieMod3__c,
                                                                                    AccessorieSp3__c,
                                                                                    AccessorieNum3__c,
                                                                                    AccessorieSize3__c,
                                                                                    MainSupplier__c,MainSupplier__r.Name,
                                                                                    InstallationLocation__c,InstallationLocation__r.Name,
                                                                                    ProductName2__c,
                                                                                    SetupFeeFlag__c,
                                                                                    Category__c,
                                                                                    KENSpecialDiscountFlag__c,
                                                                                    DiscountFlag__c,
                                                                                    ProductCategory__r.FeeType__c
                                                                             FROM CustomObjectProductMaster__c 
                                                                             WHERE Id = :productMasterId
                                                                            ];
        if (customObjectProductMasterList.size() > 0) {
            return customObjectProductMasterList[0];
        }
        
        return null;
    }
    
    /** 
     * 仕入別メーカー別マスタから仕入率、販売率を検索して
     * productMasterId  商品マスタID
     * vendorId  仕入先ID
     */
    @AuraEnabled
    public static PurchaseProductMaster__c getPurchaseProductMasterInfo(String productMasterId , String vendorId){
    	//商品マスタ情報からメーカーIDを取得する。
    	CustomObjectProductMaster__c customObjectProductMasterInfo = [SELECT Id,Name,Maker__c 
    	                                                              FROM CustomObjectProductMaster__c 
    	                                                              WHERE Id = :productMasterId
    	                                                             ];
    	system.debug(customObjectProductMasterInfo);
    	
        List<PurchaseProductMaster__c> purchaseProductMasterList = new List<PurchaseProductMaster__c>();
        
        PurchaseProductMaster__c purchaseProductMasterInfo = null;
        
        purchaseProductMasterList = [SELECT Id,Name,PurchaseRate__c,SellingRate__c,ProductMaster__c
                                     FROM PurchaseProductMaster__c
                                     WHERE Vendor__c = :vendorId
                                     AND Maker__c = :customObjectProductMasterInfo.Maker__c
                                    ];
        
        for (PurchaseProductMaster__c purchaseProductMaster : purchaseProductMasterList) {
            if (purchaseProductMaster.ProductMaster__c == productMasterId) {
                purchaseProductMasterInfo = purchaseProductMaster;
            }
        }

        if ( purchaseProductMasterInfo == null && purchaseProductMasterList.size() > 0 ) {
            purchaseProductMasterInfo = purchaseProductMasterList[0];
        }
        system.debug(purchaseProductMasterInfo);
        return purchaseProductMasterInfo;
    }
    
    /** 
     * 在庫案件商品を更新
     */
    @AuraEnabled
    public static void updateInvOppProducts(String id){
        OpportunityProduct__c oppProduct = [SELECT Id,Name,UnitPriceLease__c,Quantity__c,MakerPrice__c,MonthlyLeaseRate__c,SalesCost__c,RankRate__c,
                                                   Delivery__c,Purchase__c,Estimates__c,ProductFlag__c,
                                                   KENSpecialDiscountFlag__c,
                                                   DiscountFlag__c,
                                                   SetupFeeFlag__c,
                                                   FeeType__c,
                                                   Rank__c,
                                                   //SellingRate__c,
                                                   (SELECT Id,Name,UnitPriceLease__c FROM Rel_IHmV__r) 
                                            FROM OpportunityProduct__c 
                                            WHERE ID = :id];
        
        if (oppProduct.Quantity__c != 0) {
            for (InventoryOpportunityProduct__c invOppProduct : oppProduct.Rel_IHmV__r) {
                invOppProduct.UnitPriceLease__c = oppProduct.UnitPriceLease__c;        //計算価値価格
                //invOppProduct.RankRate__c = oppProduct.RankRate__c;                    //ランク率
                invOppProduct.SalesCost__c = oppProduct.SalesCost__c;                  //下代
                invOppProduct.MonthlyLeaseRate__c = oppProduct.MonthlyLeaseRate__c;    //月額リース料率
                invOppProduct.MakerPrice__c = oppProduct.MakerPrice__c;                //標準小売価格(単価)
            }
            update oppProduct.Rel_IHmV__r;
        }
        if (oppProduct.Rel_IHmV__r.size() <  oppProduct.Quantity__c) {//数量増えるの場合、在庫案件商品を作成
        	Estimate__c estimate = [SELECT Id,Name ,Opportunity__c,CreatedById,ExpirationDate__c,(SELECT Id,Name FROM Estimate__r)
    	                        FROM Estimate__c
    	                        WHERE Id = :oppProduct.Estimates__c];
            //新規在庫案件商品リスト
            List<InventoryOpportunityProduct__c> newInvOppProductList = new List<InventoryOpportunityProduct__c>();
            for (Integer i = 0 ; i < oppProduct.Quantity__c - oppProduct.Rel_IHmV__r.size(); i++) {
                //在庫案件商品論理の作成
                newInvOppProductList.add(createInvOppProductMain(oppProduct,estimate));
            }
            //在庫案件商品をデータベースにインサート
            insert newInvOppProductList;
        } else if (oppProduct.Rel_IHmV__r.size() >  oppProduct.Quantity__c) {//数量減らすの場合、在庫案件商品を削除
        	//新規在庫案件商品リスト
            List<InventoryOpportunityProduct__c> deleteInvOppProductList = new List<InventoryOpportunityProduct__c>();
            for (Integer i = 0 ; i < oppProduct.Rel_IHmV__r.size() - oppProduct.Quantity__c; i++) {
                //在庫案件商品を削除
                deleteInvOppProductList.add(oppProduct.Rel_IHmV__r[i]);
            }
            delete deleteInvOppProductList;
        }
    }

    /** 
     * 在庫案件商品を作成
     */
    @AuraEnabled
    public static void createInvOppProducts(String id){
        OpportunityProduct__c oppProduct = [SELECT Id,Name,UnitPriceLease__c,Quantity__c,MakerPrice__c,MonthlyLeaseRate__c,SalesCost__c,RankRate__c,
                                                   Delivery__c,Purchase__c,Estimates__c,ProductFlag__c,Rank__c,SellingRate__c,
                                                   KENSpecialDiscountFlag__c,
                                                   DiscountFlag__c,
                                                   SetupFeeFlag__c,
                                                   FeeType__c
                                            FROM OpportunityProduct__c 
                                            WHERE ID = :id];
        Estimate__c estimate = [SELECT Id,Name ,Opportunity__c,CreatedById,ExpirationDate__c,(SELECT Id,Name FROM Estimate__r)
    	                        FROM Estimate__c
    	                        WHERE Id = :oppProduct.Estimates__c];
        //新規在庫案件商品リスト
        List<InventoryOpportunityProduct__c> newInvOppProductList = new List<InventoryOpportunityProduct__c>();
        for (Integer i = 0 ; i < oppProduct.Quantity__c ; i++) {
            //在庫案件商品論理の作成
            newInvOppProductList.add(createInvOppProductMain(oppProduct,estimate));
        }
        //在庫案件商品をデータベースにインサート
        insert newInvOppProductList;
    }
    
    /** 
     * 在庫案件商品の作成メイン処理
     */ 
    public static InventoryOpportunityProduct__c createInvOppProductMain(OpportunityProduct__c oppProduct,Estimate__c estimate) {
        InventoryOpportunityProduct__c invOppProduct = new InventoryOpportunityProduct__c();
        invOppProduct.OpportunityProduct__c = oppProduct.Id;     //商品ID
        invOppProduct.Haisou__c = oppProduct.Delivery__c;        //配送
        //invOppProduct.Purchase__c = oppProduct.Purchase__c;    //仕入
        invOppProduct.Agreement__c = estimate.Estimate__r[0].Id; //更新
        invOppProduct.Rank__c = oppProduct.Rank__c;              //ランク
        invOppProduct.RankRate__c = oppProduct.RankRate__c;      //ランク率
        //invOppProduct.SellingRate__c = oppProduct.SellingRate__c;//販売率
        invOppProduct.SalesCost__c = oppProduct.SalesCost__c;    //下代
        invOppProduct.UnitPriceLease__c = oppProduct.UnitPriceLease__c;        //計算価値価格
        invOppProduct.MonthlyLeaseRate__c = oppProduct.MonthlyLeaseRate__c;    //月額リース料率
        invOppProduct.MakerPrice__c = oppProduct.MakerPrice__c;                //標準小売価格(単価)
        invOppProduct.KENSpecialDiscountFlag__c = oppProduct.KENSpecialDiscountFlag__c;    //KEN様特別値引きフラグ
        invOppProduct.DiscountFlag__c = oppProduct.DiscountFlag__c;            //出精値引フラグ
        invOppProduct.SetupFeeFlag__c = oppProduct.SetupFeeFlag__c;            //費用フラグ
        invOppProduct.FeeType__c = oppProduct.FeeType__c;                      //費用分類
        if (!oppProduct.ProductFlag__c) {
            invOppProduct.Status__c = '在庫';                                  //ステータス
        }
        return invOppProduct;
    }

	/**
     * 初期化明細
     */
    public class InitDetail {
        /**
         * 商品
         */
        @AuraEnabled
        public OpportunityProduct__c oppProduct { set; get; }
        
        /**
         * 画像URL
         */
        @AuraEnabled
        public String pictureURL { set; get; }
        
        /**
         * カテゴリーリスト
         */
        @AuraEnabled
        public List<String> imgIds { set; get; }

    }
}