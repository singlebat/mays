/** 
 * 在庫商品選択画面に向けコントローラです。
 */
public class OppProductCreateController extends CommonUntil{
	
	/** 
     * 初期化処理  初期化するとき、在庫の検索が要らない.
     */ 
	@AuraEnabled
	public static InitDetail initAction(){
		//変数初期化処理
		InitDetail initDetail = new InitDetail();
		SearchCondition conditionArea = new SearchCondition();
		List<InventoryProduct__c> inventoryProducts = null;
		
		//カテゴリー分類取得処理
		List<BigType> bigTypeList = getCategoryType();
		initDetail.packageProductMasters = getPackageProductMasters();
		system.debug('bigTypeList:' + bigTypeList);
		
		//検索条件エリアの初期値を設定する。
		conditionArea.rank = CommonUntil.getPicklist( 'InventoryProduct__c','Rank__c');
		conditionArea.shortTerm = false;
		conditionArea.specialFlg = false;
		
		//初期リストに検索条件エリアと在庫商品明細を入れます。
		initDetail.conditionArea = conditionArea;
		initDetail.bigTypeList = bigTypeList;
	    return initDetail;
	}
	
	/** 
     * カテゴリー分類取得処理
     */
    public static List<CommonUntil.Option> getPackageProductMasters(){
    	//設置場所オプションリスト
    	List<CommonUntil.Option> packageProductMasters = new List<CommonUntil.Option>();
    	//商品カテゴリーの初期動態設定処理
		List<CustomObjectProductMaster__c> productMasters  = [SELECT Id,ProductName2__c
		                                                      FROM CustomObjectProductMaster__c
		                                                      WHERE ProductCategory__r.PackageProductFlag__c = true
		                                                      order by Name
		                                                     ];
		
		for(CustomObjectProductMaster__c customObjectProductMaster : productMasters){
			CommonUntil.Option productMasterOption = new CommonUntil.Option();
    	    productMasterOption.label = customObjectProductMaster.ProductName2__c;
            productMasterOption.value = customObjectProductMaster.Id;
		    packageProductMasters.add(productMasterOption);
		}
        return packageProductMasters;
    }
	
	/** 
     * カテゴリー分類取得処理
     */
    public static List<BigType> getCategoryType(){
    	
    	//商品カテゴリーの初期動態設定処理
		List<CustomObjectProductCategory__c> categoryList  = [SELECT BigType__c,
		                                                             MediumType__c,
		                                                             SmallType__c
		                                                             FROM CustomObjectProductCategory__c
		                                                             WHERE costFlg__c = false
		                                                             //AND PackageProductFlag__c = false
		                                                             order by SortNo__c,BigType__c,MediumType__c,SmallType__c];
    	
    	//各分類変数初期化
        List<BigType> bigTypeList = new List<BigType>();
        String oldBigType;
        String oldmediumType;
        String oldSmallType;
        //検索されたカテゴリーを繰り返して、カテゴリー分類リストを作成。
        for (CustomObjectProductCategory__c customCategory : categoryList) {
        	String bigTypeName = customCategory.BigType__c;
        	String mediumTypeName = customCategory.MediumType__c;
        	String smallTypeName = customCategory.SmallType__c;
        	//大分類がない場合、処理を飛ばします。
        	if (bigTypeName != null && bigTypeName != '') {
        		//退避処理
        	    if (oldBigType != bigTypeName) {//大分類一致していないの場合、新しい大分類を作成します。
        	        BigType bigType = new BigType();
        	        bigType.bigTypeName = bigTypeName;
        	        if (mediumTypeName != null && mediumTypeName != '') {
        	        	List<mediumType> mediumTypeList = new List<mediumType>();
        	            mediumType mediumType = new mediumType();
        	            mediumType.mediumTypeName = mediumTypeName;
        	            if (smallTypeName != null && smallTypeName != '') {
        	                List<String> smallTypeNameList = new List<String>();
        	                smallTypeNameList.add(smallTypeName);
        	                mediumType.smallTypeList = smallTypeNameList;
        	            }
        	            mediumTypeList.add(mediumType);
        	            bigType.mediumTypeList = mediumTypeList;
        	        }
        	        bigTypeList.add(bigType);
        	    } else {//大分類一致しているの場合
        	        if (mediumTypeName != oldmediumType) {//中分類一致していないの場合、この大分類に新しい中分類を作成します。
        	            mediumType mediumType = new mediumType();
        	            mediumType.mediumTypeName = mediumTypeName;
        	            if (smallTypeName != null && smallTypeName != '') {
        	                List<String> smallTypeNameList = new List<String>();
        	                smallTypeNameList.add(smallTypeName);
        	                mediumType.smallTypeList = smallTypeNameList;
        	            }
        	            if (bigTypeList.get(bigTypeList.size()-1).mediumTypeList.size() != 0 ) {
        	                bigTypeList.get(bigTypeList.size()-1).mediumTypeList.add(mediumType);
        	            } else {
        	                List<mediumType> mediumTypeList = new List<mediumType>();
        	                mediumTypeList.add(mediumType);
        	                bigTypeList.get(bigTypeList.size()-1).mediumTypeList = mediumTypeList;
        	            }
        	        } else {//中分類一致しているの場合、この中分類に小分類を追加作成します。
                        if (bigTypeList.get(bigTypeList.size()-1).mediumTypeList.get(bigTypeList.get(bigTypeList.size()-1).mediumTypeList.size() - 1).smallTypeList.size() != 0 ) {
        	                bigTypeList.get(bigTypeList.size()-1).mediumTypeList.get(bigTypeList.get(bigTypeList.size()-1).mediumTypeList.size() - 1).smallTypeList.add(smallTypeName);
        	            } else {
        	            	List<String> smallTypeNameList = new List<String>();
        	                smallTypeNameList.add(smallTypeName);
        	                bigTypeList.get(bigTypeList.size()-1).mediumTypeList.get(bigTypeList.get(bigTypeList.size()-1).mediumTypeList.size() - 1).smallTypeList = smallTypeNameList;
        	            }
        	        }
        	    }
        	}
        	oldBigType = bigTypeName;
        	oldmediumType = mediumTypeName;
        	oldSmallType = smallTypeName;
        }
        return bigTypeList;
    }
	
	/** 
     * 検索された在庫商品の設定
     */
    public static List<InventoryProductDetail> setInventoryProducts(List<InventoryProduct__c> inventoryProducts){
    	//在庫商品明細リストの初期化
    	List<InventoryProductDetail> InventoryProductDetailList = new List<InventoryProductDetail>();
        //在庫商品を繰り返して、在庫商品明細リストに設定する。
		Integer countNo = 0;
		for (InventoryProduct__c inventoryProduct : inventoryProducts) {
		    InventoryProductDetail inventoryProductDetail = new InventoryProductDetail();
		    inventoryProductDetail.detailNo = countNo;   //明細番号
		    inventoryProductDetail.ID = inventoryProduct.Id;    //在庫商品ID
		    inventoryProductDetail.Name = inventoryProduct.Name;    //在庫番号
		    inventoryProductDetail.imgUrl = inventoryProduct.PictureURL1__c;    //メイン画像URL
		    inventoryProductDetail.selectKBN = false;    //選択かどうか区分
		    inventoryProductDetail.valuePrice = inventoryProduct.ValuePrice__c;    //評価価値価格
		    inventoryProductDetail.currentStatus = inventoryProduct.CurrentStatus__c;    //現状区分
		    inventoryProductDetail.currentStatusAuxiliary = inventoryProduct.CurrentStatusAuxiliary__c;    //現状補助区分
		    inventoryProductDetail.productMasterID = inventoryProduct.ProductMaster__c;    //商品マスタID
		    inventoryProductDetail.installationLocationId = inventoryProduct.InstallationLocation__c;    //設置場所
		    //inventoryProductDetail.productName = inventoryProduct.ProductName__c;    //商品名
		    inventoryProductDetail.productName = inventoryProduct.OtherProductName__c;    //商品名
		    inventoryProductDetail.sellingRate  = inventoryProduct.SellingRate2__c;    //販売率
            inventoryProductDetail.purchaseRate  = inventoryProduct.PurchaseRate__c;    //仕入率
            inventoryProductDetail.rank  = inventoryProduct.Rank__c;    //ランク
            inventoryProductDetail.rankRate  = inventoryProduct.RankRate__c;    //ランク
            inventoryProductDetail.nyukoyoteibi  = inventoryProduct.nyukoyoteibi__c;    //入庫予定日
            inventoryProductDetail.receiptDate  = inventoryProduct.ReceiptDate__c;    //入庫日
            inventoryProductDetail.setNo = inventoryProduct.SetNo__c;    //セット番号
            inventoryProductDetail.makerName = inventoryProduct.ProductMaster__r.Maker__r.Name;    //メーカー名
            inventoryProductDetail.makerPrice = inventoryProduct.ProductPrice__c;    //商品定価
            inventoryProductDetail.modelNumber = inventoryProduct.ModelNumber__c;    //型番
            inventoryProductDetail.size = inventoryProduct.Size__c;    //サイズ
            inventoryProductDetail.salesCost = inventoryProduct.SalesCost__c;    //下代
            inventoryProductDetail.imgsId = new List<Id>(new Map<Id, CombinedAttachment>(inventoryProduct.CombinedAttachments).keySet());    //画像ContentDocumentのID
            system.debug('imgsId:' + inventoryProductDetail.imgsId);
		    InventoryProductDetailList.add(inventoryProductDetail);
		    countNo ++;
		}
		
		return InventoryProductDetailList;
    }

	/** 
     * 検索ボタンを押して、検索処理を行う。
     */ 
	@AuraEnabled
	public static List<InventoryProductDetail> searchInventoryProduct(String categoryName , String conditionArea,List<String> currentStatus,List<String> rank){
		system.debug('currentStatus' + currentStatus);
		system.debug('rank' + rank);
		
		// 検索条件
        SearchCondition condition = (SearchCondition)JSON.deserialize(conditionArea, SearchCondition.class);
        system.debug('condition' + condition);
		system.debug('searchBar' + condition.searchBar);
		
		Date nyukoyoteibiLowerLimit; 
		Date nyukoyoteibiUpLimit;
		Integer heightLowerLimit = condition.heightLowerLimit;
		Integer heightUpLimit = condition.heightUpLimit;
		Integer widthLowerLimit = condition.widthLowerLimit;
		Integer widthUpLimit = condition.widthUpLimit;
		Integer depthLowerLimit = condition.depthLowerLimit;
		Integer depthUpLimit = condition.depthUpLimit;
		Integer priceLowerLimit = condition.priceLowerLimit;
		Integer priceUpLimit = condition.priceUpLimit;
		String searchBar = condition.searchBar;
		String bigType;
		String mediumType;
		String smallType;
		
		//SQLを作成
		String sqlQuery = 'SELECT Id,Name,PictureURL1__c,ProductName__c,OtherProductName__c,CurrentStatus__c,SetNo__c,InstallationLocation__c,';
		sqlQuery += ' CurrentStatusAuxiliary__c,ValuePrice__c,PurchaseName__c,ProductMaster__c,RankRate__c,';
		sqlQuery += ' SellingRate2__c,PurchaseRate__c,Rank__c,nyukoyoteibi__c,ReceiptDate__c,(SELECT Id FROM CombinedAttachments),';
		sqlQuery += ' ProductMaster__r.Maker__r.Name,ProductMaster__r.ListPrice__c,ModelNumber__c,';
		sqlQuery += ' Size__c,ProductPrice__c,';
		sqlQuery += ' SalesCost__c';
		
		sqlQuery += ' FROM InventoryProduct__c';
		sqlQuery += ' WHERE HOLD__c = false ';
		sqlQuery += ' AND ProductMaster__r.ProductCategory__r.costFlg__c = false ';
		
        if (categoryName != null && categoryName != '') {//カテゴリー検索条件
            List<String> categoryNameList = categoryName.split(' > ');
            system.debug(categoryNameList);
            bigType = categoryNameList[0];
            sqlQuery += ' AND ProductMaster__r.ProductCategory__r.BigType__c = :bigType ';
            if (categoryNameList.size() >= 2 ) {
            	mediumType = categoryNameList[1];
                sqlQuery += ' AND ProductMaster__r.ProductCategory__r.mediumType__c = :mediumType ';
                if (categoryNameList.size() >= 3) {
                	smallType = categoryNameList[2];
                    sqlQuery += ' AND ProductMaster__r.ProductCategory__r.SmallType__c = :smallType ';
                }
            }
        } 
        //現状区分条件編集
        sqlQuery += ' AND ((CurrentStatus__c = \'在庫\' AND (CurrentStatusAuxiliary__c = \'メンテ済\' ';
        if (currentStatus.size() > 0) {
        	String strCurrentStatus = ''; 
            for (String str : currentStatus) {
            	strCurrentStatus += str;
            }
            if (strCurrentStatus.contains('未メンテ')) {
                sqlQuery += ' OR CurrentStatusAuxiliary__c = \'未メンテ\')) ';
            } else {
                sqlQuery += ' )) ';
            }
            if (strCurrentStatus.contains('リース未入庫')) {
                sqlQuery += ' OR (CurrentStatus__c = \'リース中\' AND CurrentStatusAuxiliary__c = \'返却予定\' )) ';
            } else {
                sqlQuery += ' ) ';
            }
        } else {
            sqlQuery += ')))';
        }
        
        //スペシャルフラグ
        if (condition.specialFlg) {
            sqlQuery += ' AND specialFlg__c = True ';
        }
        
        //短期利用条件編集
        if (condition.shortTerm) {
            sqlQuery += ' AND LongOrShort__c = \'短期専用\' ';
        } 
        
        //入庫予定日条件編集
        if (condition.nyukoyoteibiLowerLimit != null && condition.nyukoyoteibiLowerLimit != '') {
            nyukoyoteibiLowerLimit = Date.valueOf(condition.nyukoyoteibiLowerLimit); 
            sqlQuery += ' AND nyukoyoteibi__c >= :nyukoyoteibiLowerLimit ';
        }
        if (condition.nyukoyoteibiUpLimit != null && condition.nyukoyoteibiUpLimit != '') {
            nyukoyoteibiUpLimit = Date.valueOf(condition.nyukoyoteibiUpLimit); 
            sqlQuery += ' AND nyukoyoteibi__c <= :nyukoyoteibiUpLimit ';
        }
        
        //高さ条件編集
        if (condition.heightLowerLimit != null) {
            sqlQuery += ' AND Height__c >= :heightLowerLimit ';
        }
        if (condition.heightUpLimit != null) { 
            sqlQuery += ' AND Height__c <= :heightUpLimit ';
        }
        
        //幅条件編集
        if (condition.widthLowerLimit != null) {
            sqlQuery += ' AND Width__c >= :widthLowerLimit ';
        }
        if (condition.widthUpLimit != null) {
            sqlQuery += ' AND Width__c <= :widthUpLimit ';
        }
        
        //奥行条件編集
        if (condition.depthLowerLimit != null) {
            sqlQuery += ' AND Depth__c >= :depthLowerLimit ';
        }
        if (condition.depthUpLimit != null) {
            sqlQuery += ' AND Depth__c <= :depthUpLimit ';
        }
        
        //評価価値価格条件編集
        if (condition.priceLowerLimit != null) {
            sqlQuery += ' AND ValuePrice__c >= :priceLowerLimit ';
        }
        if (condition.priceUpLimit != null) {
            sqlQuery += ' AND ValuePrice__c <= :priceUpLimit ';
        }
        
        //ランク条件編集
        system.debug(rank.size());
        if (rank.size() > 0) {
            sqlQuery += ' AND Rank__c in :rank ';
        }
        
        //フリーワード検索
        if (searchBar != null && searchBar != '') {
        	String[] keyword = (searchBar.replaceAll('　',' ')).split(' ');
        	for (String str : keyword) {
        		if (!String.isBlank(str)) {
        		    str = '\'%' + str + '%\'';
        	        sqlQuery += ' AND (Name like ' + str + ' OR ProductName__c like ' + str + ' OR PurchaseName__r.Name like ' + str + ' OR Maker__c like ' + str + '  ';
                    sqlQuery += ' OR ProductMaster__r.Name like ' + str + ' OR Color__c like ' + str + ' OR Size__c like ' + str + ' OR Specification__c like ' + str + '';
                    sqlQuery += ' OR ModelTotal__c like ' + str + ' OR YoRyo__c like ' + str + ' OR SetNo__c like ' + str + '';
                    sqlQuery += ' OR Specification1__c like ' + str + ' OR Specification2__c like ' + str + ' OR Specification3__c like ' + str + ' OR Specification4__c like ' + str + ' ';
                    sqlQuery += ' OR Specification5__c like ' + str + ' OR Specification6__c like ' + str + ' OR Specification7__c like ' + str + ' OR Specification8__c like ' + str + ' )';
        		}
        	}
        }

		sqlQuery += ' order by Name';
		
		system.debug(sqlQuery);
        system.debug(bigType);
        system.debug(priceLowerLimit);
		List<InventoryProduct__c> inventoryProducts = Database.query(sqlQuery);
		if (inventoryProducts.size() > 0) {
			system.debug(inventoryProducts[0]);
			List<InventoryProductDetail> InventoryProductDetailList = setInventoryProducts(inventoryProducts);
		    return InventoryProductDetailList;
		}

	    return null;
	}
	
	/** 
     * 選択ボタンを押して、商品登録処理を行う。
     */ 
	@AuraEnabled
	public static List<InventoryOpportunityProduct__c> productSelected(String inventoryProductObj, String estimatecId){

        //在庫商品明細
        InventoryProductDetail inventoryProduct = (InventoryProductDetail)JSON.deserialize(inventoryProductObj, InventoryProductDetail.class);
        
        InventoryProduct__c zaikoProduct = [SELECT Id,Name ,HOLD__c
                                                   FROM InventoryProduct__c
                                                   WHERE Id = :inventoryProduct.Id];
        //HOLDしたの場合、他の人より、この商品既に選択されたと想定して、登録処理を行いません。
        if (zaikoProduct.HOLD__c) {
            return null;
        }
        
        //見積情報取得
        Estimate__c estimateObj = [SELECT Id,Name,Opportunity__c,CreatedById,
                                          RecordType.Name,MonthlyLeaseRate__c,
                                          (SELECT Id FROM rel_Delivery__r),
                                          (SELECT Id FROM Estimate__r)
                                   FROM Estimate__c
                                   WHERE Id = :estimatecId
                                  ];
        
        //新規商品リスト
        List<OpportunityProduct__c> oppProducts = new List<OpportunityProduct__c>();
        //新規在庫案件商品リスト
        List<InventoryOpportunityProduct__c> newInvOppProductList = new List<InventoryOpportunityProduct__c>();
        
        //SQLを作成
		String sqlQuery = 'SELECT Id,Name,PictureURL1__c,ProductName__c,OtherProductName__c,CurrentStatus__c,SetNo__c,InstallationLocation__c,';
		sqlQuery += ' CurrentStatusAuxiliary__c,ValuePrice__c,PurchaseName__c,ProductMaster__c,RankRate__c,';
		sqlQuery += ' SellingRate2__c,PurchaseRate__c,Rank__c,nyukoyoteibi__c,ReceiptDate__c,(SELECT Id FROM CombinedAttachments),';
		sqlQuery += ' ProductMaster__r.Maker__r.Name,ProductMaster__r.ListPrice__c,ModelNumber__c,';
		sqlQuery += ' Height__c,Height2__c,Width__c,Depth__c,Diameter__c,Size__c,ProductPrice__c,';
		sqlQuery += ' Specification1__c,Specification2__c,Specification3__c,Specification4__c,';
		sqlQuery += ' Specification5__c,Specification6__c,Specification7__c,Specification8__c,SalesCost__c,';
		sqlQuery += ' Accessories__c, AccessorieMod1__c,AccessorieSp1__c,AccessorieNum1__c,AccessorieSize1__c,';
		sqlQuery += ' Accessories2__c,AccessorieMod2__c,AccessorieSp2__c,AccessorieNum2__c,AccessorieSize2__c,';
		sqlQuery += ' Accessories3__c,AccessorieMod3__c,AccessorieSp3__c,AccessorieNum3__c,AccessorieSize3__c,';
		sqlQuery += ' ProductMaster__r.ProductCategory__r.NotNeedHold__c';
		
		sqlQuery += ' FROM InventoryProduct__c';
		if (inventoryProduct.setNo != null && inventoryProduct.setNo != '') {
		    sqlQuery += ' WHERE SetNo__c =  \'' + inventoryProduct.setNo + '\'';
		} else {
		    sqlQuery += ' WHERE Id =  \'' + zaikoProduct.Id + '\'';
		}
		
		system.debug(sqlQuery);
        List<InventoryProduct__c> inventoryProducts = Database.query(sqlQuery);
        
        //在庫商品の更新 HOLDになる
        for (InventoryProduct__c updateInProduct : inventoryProducts) {
        	//商品を作成
            oppProducts.add(CreateProducts(updateInProduct,estimateObj));
            //在庫案件商品の追加
            newInvOppProductList.add(createInvOppProduct(updateInProduct,estimateObj));
            //HOLD不要かどうか判断する。
            if (!updateInProduct.ProductMaster__r.ProductCategory__r.NotNeedHold__c) {
                //在庫の更新
                updateInProduct.Oppotunity__c = estimateObj.Opportunity__c;      //案件
                updateInProduct.Estimate__c = estimateObj.Id;                    //見積
                updateInProduct.Agreement__c = estimateObj.Estimate__r[0].Id;    //更新
                updateInProduct.HOLD__c = true;                                  //HOLD区分
                updateInProduct.Haisou__c = estimateObj.rel_Delivery__r[0].Id;   //配送
                updateInProduct.HOLDUser__c = estimateObj.CreatedById;           //HOLD担当者は見積所有者
            }
        }
        update inventoryProducts;
        
        //商品のインサート
        insert oppProducts;
        
        //在庫案件商品は商品と紐づく。
        for (Integer i = 0 ; i <  oppProducts.size() ; i++) {
            newInvOppProductList[i].OpportunityProduct__c = oppProducts[i].Id;    //商品ID
        }
        //在庫案件商品のインサート
        insert newInvOppProductList;

        return newInvOppProductList;
	}
	
    /** 
     * 在庫案件商品を作成
     */ 
    private static InventoryOpportunityProduct__c createInvOppProduct(InventoryProduct__c invProductDetail,Estimate__c estimateObj) {
        InventoryOpportunityProduct__c invOppProduct = new InventoryOpportunityProduct__c();
        invOppProduct.InventoryProduct__c = invProductDetail.ID;        //在庫ID
        invOppProduct.Haisou__c = estimateObj.rel_Delivery__r[0].Id;    //配送
        invOppProduct.Agreement__c = estimateObj.Estimate__r[0].Id;     //更新
        invOppProduct.RankRate__c = invProductDetail.RankRate__c;       //ランク率
        invOppProduct.Rank__c = invProductDetail.Rank__c;               //ランク
        //invOppProduct.SellingRate__c = invProductDetail.SellingRate__c; //販売率
        //invOppProduct.SalesCost__c = invProductDetail.SalesCost__c;     //下代
        invOppProduct.SalesCost__c = 0;     //下代
        invOppProduct.UnitPriceLease__c = invProductDetail.ValuePrice__c;        //計算価値価格
        invOppProduct.MonthlyLeaseRate__c = estimateObj.MonthlyLeaseRate__c;     //月額リース料率
        invOppProduct.MakerPrice__c = invProductDetail.ProductPrice__c;          //標準小売価格(単価)
        invOppProduct.Status__c = invProductDetail.CurrentStatus__c;             //ステータス
        return invOppProduct;
    }
	
	/** 
     * 商品の作成
     */ 
	@AuraEnabled
	public static OpportunityProduct__c CreateProducts(InventoryProduct__c inventoryProduct, Estimate__c estimateObj){
	    //商品の作成
        OpportunityProduct__c opportunityProduct = new OpportunityProduct__c();
        opportunityProduct.SetNo__c = inventoryProduct.SetNo__c;               //セット番号  
        opportunityProduct.Product__c = inventoryProduct.ProductMaster__c;     //商品マスタ
        //opportunityProduct.name  = inventoryProduct.ProductName__c;            //商品名
        opportunityProduct.name  = inventoryProduct.OtherProductName__c;       //商品名
        opportunityProduct.ProductType__c = '在庫品';                          //商品区分
        opportunityProduct.Rank__c  = inventoryProduct.Rank__c;                //ランク
        opportunityProduct.RankRate__c  = inventoryProduct.RankRate__c;        //ランク率
        opportunityProduct.InstallationLocation__c  = inventoryProduct.InstallationLocation__c;    //設置場所
        opportunityProduct.Quantity__c = 1;                                     //数量
        opportunityProduct.MakerPrice__c = inventoryProduct.ProductPrice__c;    //標準小売価格(単価)
        if (inventoryProduct.SellingRate2__c != null) {
            opportunityProduct.SellingRate__c = inventoryProduct.SellingRate2__c;//販売率
        }
        if (estimateObj.RecordType.Name == 'リース') {
            opportunityProduct.UnitPriceLease__c = inventoryProduct.ValuePrice__c;          //計算価値価格
            opportunityProduct.MonthlyLeaseRate__c =  estimateObj.MonthlyLeaseRate__c;      //月額リース料率
        }
        if (estimateObj.RecordType.Name == '販売') {
            //opportunityProduct.UnitPriceSelling__c =  inventoryProduct.ValuePrice__c;       //販売価値価格(単価)
            opportunityProduct.UnitPriceLease__c =  inventoryProduct.ValuePrice__c;       //計算価値価格
        }
        
        opportunityProduct.ModelNumber__c = inventoryProduct.ModelNumber__c;    //型番
        opportunityProduct.Height__c = inventoryProduct.Height__c;              //高さ
        opportunityProduct.Width__c = inventoryProduct.Width__c;                //幅
        opportunityProduct.Depth__c = inventoryProduct.Depth__c;                //奥行
        opportunityProduct.Height2__c = inventoryProduct.Height2__c;            //高さⅡ
        opportunityProduct.Diameter__c = inventoryProduct.Diameter__c;          //直径
        opportunityProduct.Accessories__c = inventoryProduct.Accessories__c;          //付属品1
        opportunityProduct.AccessorieMod1__c = inventoryProduct.AccessorieMod1__c;    //付属品1型番
        opportunityProduct.AccessorieSp1__c = inventoryProduct.AccessorieSp1__c;      //付属品1仕様
        opportunityProduct.AccessorieNum1__c = inventoryProduct.AccessorieNum1__c;    //付属品1数量
        opportunityProduct.AccessorieSize1__c = inventoryProduct.AccessorieSize1__c;  //付属品1サイズ
        opportunityProduct.Accessories2__c = inventoryProduct.Accessories2__c;        //付属品2
        opportunityProduct.AccessorieMod2__c = inventoryProduct.AccessorieMod2__c;    //付属品2型番
        opportunityProduct.AccessorieSp2__c = inventoryProduct.AccessorieSp2__c;      //付属品2仕様
        opportunityProduct.AccessorieNum2__c = inventoryProduct.AccessorieNum2__c;    //付属品2数量
        opportunityProduct.AccessorieSize2__c = inventoryProduct.AccessorieSize2__c;  //付属品2サイズ
        opportunityProduct.Accessories3__c = inventoryProduct.Accessories3__c;        //付属品3
        opportunityProduct.AccessorieMod3__c = inventoryProduct.AccessorieMod3__c;    //付属品3型番
        opportunityProduct.AccessorieSp3__c = inventoryProduct.AccessorieSp3__c;      //付属品3仕様
        opportunityProduct.AccessorieNum3__c = inventoryProduct.AccessorieNum3__c;    //付属品3数量
        opportunityProduct.AccessorieSize3__c = inventoryProduct.AccessorieSize3__c;  //付属品3サイズ
        opportunityProduct.Specification1__c = inventoryProduct.Specification1__c;       //仕様１
        opportunityProduct.Specification2__c = inventoryProduct.Specification2__c;       //仕様２
        opportunityProduct.Specification3__c = inventoryProduct.Specification3__c;       //仕様３
        opportunityProduct.Specification4__c = inventoryProduct.Specification4__c;       //仕様４
        opportunityProduct.Specification5__c = inventoryProduct.Specification5__c;       //仕様５
        opportunityProduct.Specification6__c = inventoryProduct.Specification6__c;       //仕様６
        opportunityProduct.Specification7__c = inventoryProduct.Specification7__c;       //仕様７
        opportunityProduct.Specification8__c = inventoryProduct.Specification8__c;       //仕様８
        opportunityProduct.SalesCost__c = 0;                                   //下代           
        opportunityProduct.Estimates__c = estimateObj.Id;                      //見積
        opportunityProduct.Contract__c = estimateObj.Estimate__r[0].Id;        //契約
        opportunityProduct.PictureURL1__c = inventoryProduct.PictureURL1__c;
        //仕様書にないですが、一旦在庫品を選択して、配送の場合は必要があると思います。
        opportunityProduct.HaisouType__c = '入庫';                             //配送区分
        opportunityProduct.Delivery__c = estimateObj.rel_Delivery__r[0].Id;    //配送
        //在庫品として登録した商品のステータスは在庫とする。
        opportunityProduct.PurchaseStatus__c = '在庫';                         //商品ステータス
        //商品一覧表示項目:在庫番号
        opportunityProduct.InventoryProductNo__c = inventoryProduct.Name;
        //商品一覧表示項目:在庫ID
        opportunityProduct.InventoryProductID__c = inventoryProduct.ID;
        //商品一覧表示項目:現状区分
        opportunityProduct.CurrentStatus__c = inventoryProduct.CurrentStatus__c;
        
        return opportunityProduct;
	}
	
	/** 
     * 選択済ボタンを押して、商品削除処理を行う。
     */ 
	@AuraEnabled
	public static void deleteProduct(String inventoryProductObj, String estimatecId){
        //在庫商品
        InventoryProductDetail inventoryProduct = (InventoryProductDetail)JSON.deserialize(inventoryProductObj, InventoryProductDetail.class);
        
        //商品の削除 且 在庫商品の更新 HOLD解除
        ProductEditListController.deletedRecordById(inventoryProduct.opportunityProductID);
	}
    
    /** 
     * レポートURL取得
     * reportName レポートの一意名前
     * recordId 見積ID
     */ 
	/*@AuraEnabled
	public static String getReportURL(String reportName,String recordId){

        Id id = CommonUntil.getReportId(reportName);
        
        return URL.getSalesforceBaseUrl().toExternalForm() + '/one/one.app#/sObject/' + id + '/view?fv0=' + recordId;
	}*/
	
    /** 
     * ContentDocumentIdより、ContentVersionIdを取得する。
     */ 
	@AuraEnabled
	public static List<String> getImgId(List<String> contentVersionIds){
        
        List<ContentVersion> ContentVersionList = [SELECT Id,FileType,ContentDocumentId,MainImgTime__c 
                                                   FROM ContentVersion 
                                                   WHERE ContentDocumentId IN: contentVersionIds 
                                                   ORDER BY MainImgTime__c DESC NULLS LAST];
        
        List<Id> contentDocumentIds = new List<String>();
        
        contentDocumentIds = new List<Id>(new Map<Id, ContentVersion>(ContentVersionList).keySet());
        
        return contentDocumentIds;
	}
	
    /** 
     * Package商品の作成
     * productMasterId 商品マスタID
     */ 
	@AuraEnabled
	public static InventoryProduct__c doCreatePackage(String productMasterId){
		CustomObjectProductMaster__c productMaster  = [SELECT Id,ProductName2__c,ListPrice__c
		                                               FROM CustomObjectProductMaster__c
		                                               WHERE Id = :productMasterId
		                                              ];
		//Package商品は在庫品として作成する。
		InventoryProduct__c invProduct = new InventoryProduct__c();
		invProduct.CurrentStatus__c = '在庫';    //現状区分
		invProduct.CurrentStatusAuxiliary__c = 'メンテ済';    //現状補助区分
		invProduct.ProductMaster__c = productMasterId;
		invProduct.ProductPrice__c = productMaster.ListPrice__c;
		invProduct.Rank__c = 'P';
		invProduct.PackageStatus__c = '作成中';
		
		insert invProduct;

        return [SELECT Id,Name,CurrentStatus__c,ProductMaster__c,ProductPrice__c,Rank__c,PackageStatus__c FROM InventoryProduct__c WHERE Id = :invProduct.Id];
	}
	
    /** 
     * Package商品の保存(今、状態変更だけ)
     * invProduct 在庫オブジェクト
     */ 
	@AuraEnabled
	public static void doPackageProductSave(InventoryProduct__c invProduct){
		upsert invProduct;
	}
	
	/** 
     * Package商品の確定検索
     * packageProductName Package商品の名前
     */ 
	@AuraEnabled
	public static PackageDetail doPackageProductSelect(String packageProductName){
		//パッケージ商品OBJ定義
		PackageDetail detail = new packageDetail();
		//パッケージ在庫商品を検索
		InventoryProduct__c packageInvProduct = [SELECT Id,Name,CurrentStatus__c,ProductMaster__c,ProductPrice__c,Rank__c,PackageStatus__c 
		                                         FROM InventoryProduct__c 
		                                         WHERE Name = :packageProductName];
		                                         
		detail.invProduct = packageInvProduct;
		
		//パッケージ在庫商品の中身在庫を検索
		List<InventoryProduct__c> packageProducts = [SELECT Id,Name,PictureURL1__c,ProductName__c,CurrentStatus__c,SetNo__c,InstallationLocation__c,
                                                            CurrentStatusAuxiliary__c,ValuePrice__c,PurchaseName__c,ProductMaster__c,RankRate__c,
                                                            SellingRate2__c,PurchaseRate__c,Rank__c,nyukoyoteibi__c,ReceiptDate__c,(SELECT Id FROM CombinedAttachments),
                                                            ProductMaster__r.Maker__r.Name,ProductMaster__r.ListPrice__c,ModelNumber__c,
                                                            Height__c,Height2__c,Width__c,Depth__c,Diameter__c,Accessories__c,ProductPrice__c
                                                 FROM InventoryProduct__c 
                                                 WHERE PackageProduct__c = :packageInvProduct.Id];
        
        //画面表示用明細に入れる
        List<InventoryProductDetail> invProductDetails = setInventoryProducts(packageProducts);
        for (InventoryProductDetail invProductDetail : invProductDetails) {
            invProductDetail.selectKBN = true;
        }
        detail.packageProducts = invProductDetails;
        return detail;
	}
	
	/** 
     * 選択ボタンを押して、Package商品に、商品を追加
     */ 
	@AuraEnabled
	public static void doCreatePackageProduct(String inventoryProductObj, InventoryProduct__c invProduct){

        // 在庫商品明細
        InventoryProductDetail inventoryProduct = (InventoryProductDetail)JSON.deserialize(inventoryProductObj, InventoryProductDetail.class);
        
        //パッケージ在庫商品を検索
		InventoryProduct__c packageInvProduct = [SELECT Id,Name,PackageStatus__c,PackageProduct__c
		                                         FROM InventoryProduct__c 
		                                         WHERE Id = :inventoryProduct.Id];
		packageInvProduct.PackageProduct__c = invProduct.Id;
		packageInvProduct.PackagegTargetProductFlag__c = true;
		update packageInvProduct;
	}
	
	/** 
     * 選択済みボタンを押して、Package商品から、選択された商品を削除
     */ 
	@AuraEnabled
	public static void doDeletePackageProduct(String inventoryProductObj){

        // 在庫商品明細
        InventoryProductDetail inventoryProduct = (InventoryProductDetail)JSON.deserialize(inventoryProductObj, InventoryProductDetail.class);
        
        //パッケージ在庫商品を検索
		InventoryProduct__c packageInvProduct = new InventoryProduct__c();
		packageInvProduct.Id = inventoryProduct.ID;
		packageInvProduct.PackageProduct__c = null;
		packageInvProduct.PackagegTargetProductFlag__c = false;
		update packageInvProduct;
	}
    
	/**
     * 初期化リスト
     */
    public class InitDetail {
        /**
         * 検索条件クラス
         */
        @AuraEnabled
        public SearchCondition conditionArea { set; get; }
        /**
         * カテゴリーリスト
         */
        @AuraEnabled
        public List<BigType> bigTypeList { set; get; }
        /**
         * Package商品マスタリスト
         */
    	@AuraEnabled
        public List<CommonUntil.Option> packageProductMasters;

    }
    
	/**
     * パッケージ商品OBJ
     */
    public class PackageDetail {
        /**
         * カテゴリーリスト
         */
        @AuraEnabled
        public InventoryProduct__c invProduct { set; get; }
        /**
         * Package商品マスタリスト
         */
    	@AuraEnabled
        public List<InventoryProductDetail> packageProducts;
    }
	
	/**
     * 在庫商品明細
     */
    public class InventoryProductDetail {
        /**
         * No
         */
        @AuraEnabled
        public Integer detailNo { set; get; }
        /**
         * ID
         */
        @AuraEnabled
        public String ID { set; get; }
        /**
         * 在庫番号
         */
        @AuraEnabled
        public String Name { set; get; }
        /**
         * 商品名
         */
        @AuraEnabled
        public String productName { set; get; }
        /**
         * 選択フラグ
         */
        @AuraEnabled
        public Boolean selectKBN { set; get; }
        /**
         * imgUrl
         */
        @AuraEnabled
        public String imgUrl { set; get; }
        /**
         * セット番号
         */
        @AuraEnabled
        public String setNo { set; get; }
        /**
         * 評価価値価格
         */
        @AuraEnabled
        public Decimal valuePrice { set; get; }
        /**
         * 現状区分
         */
        @AuraEnabled
        public String currentStatus { set; get; }
        /**
         * 現状補助区分
         */
        @AuraEnabled
        public String currentStatusAuxiliary { set; get; }
        /**
         * 商品マスタID
         */
        @AuraEnabled
        public String productMasterID { set; get; }
        /**
         * 仕入先ID
         */
        //@AuraEnabled
        //public String vendorID { set; get; }
        /**
         * 仕入率
         */
        @AuraEnabled
        public Decimal purchaseRate { set; get; }
        /**
         * 商品ID
         */
        @AuraEnabled
        public String opportunityProductID { set; get; }
        /**
         * 販売率
         */
        @AuraEnabled
        public Decimal sellingRate { set; get; }
        /**
         * 入庫予定日
         */
        @AuraEnabled
        public Date nyukoyoteibi { set; get; }
        /**
         * 入庫日
         */
        @AuraEnabled
        public Date receiptDate { set; get; }
        /**
         * ランク
         */
        @AuraEnabled
        public String rank { set; get; }
        /**
         * ランク率
         */
        @AuraEnabled
        public Decimal rankRate { set; get; }
        /**
         * 関連商品URL
         */
        @AuraEnabled
        public List<String> imgsId { set; get; }
        /**
         * メーカー名
         */
        @AuraEnabled
        public String makerName { set; get; }
        /**
         * メーカー単価
         */
        @AuraEnabled
        public Decimal makerPrice { set; get; }
        /**
         * 下代
         */
        @AuraEnabled
        public Decimal SalesCost { set; get; }
        /**
         * 設置場所ID
         */
        @AuraEnabled
        public String installationLocationId { set; get; }
        /**
         * 型番
         */
        @AuraEnabled
        public String modelNumber { set; get; }
        /**
         * サイズ
         */
        @AuraEnabled
        public String size { set; get; }
        /**
         * 付属品
         */
        @AuraEnabled
        public String accessories { set; get; }
    }
	
	/** 
     * 検索条件クラス
     */ 
    public class SearchCondition {
        /**
         * 価値価格帯上限
         */
        @AuraEnabled
        public Integer priceUpLimit { set; get; }
        /**
         * 価値価格帯下限
         */
        @AuraEnabled
        public Integer priceLowerLimit { set; get; }
        /**
         * 幅上限
         */
        @AuraEnabled
        public Integer widthUpLimit { set; get; }
        /**
         * 幅下限
         */
        @AuraEnabled
        public Integer widthLowerLimit { set; get; }
        /**
         * 高さ上限
         */
        @AuraEnabled
        public Integer heightUpLimit { set; get; }
        /**
         * 高さ下限
         */
        @AuraEnabled
        public Integer heightLowerLimit { set; get; }
        /**
         * 奥行上限
         */
        @AuraEnabled
        public Integer depthUpLimit { set; get; }
        /**
         * 奥行下限
         */
        @AuraEnabled
        public Integer depthLowerLimit { set; get; }
        /**
         * 入庫予定日上限
         */
        @AuraEnabled
        public String nyukoyoteibiUpLimit { set; get; }
        /**
         * 入庫予定日下限
         */
        @AuraEnabled
        public String nyukoyoteibiLowerLimit { set; get; }
        /**
         * ランク
         */
        @AuraEnabled
        public List<CommonUntil.Option> rank { set; get; }
        /**
         * 短期区分
         */
        @AuraEnabled
        public Boolean shortTerm { set; get; }
        /**
         * スペシャル区分
         */
        @AuraEnabled
        public Boolean specialFlg { set; get; }
        /**
         * サーチバー
         */
        @AuraEnabled
        public String searchBar { set; get; }
    }
    
    /** 
     * 大分類対象
     */ 
    public class BigType {
        /**
         * 大分類カテゴリー名
         */
        @AuraEnabled
        public String bigTypeName { set; get; }
        /**
         * 中分類対象リスト
         */
        @AuraEnabled
        public List<mediumType> mediumTypeList { set; get; }
    }
    
    /** 
     * 中分類対象
     */ 
    public class mediumType {
        /**
         * 中分類カテゴリー名
         */
        @AuraEnabled
        public String mediumTypeName { set; get; }
        /**
         * 小分類リスト
         */
        @AuraEnabled
        public List<String> smallTypeList { set; get; }
    }
}