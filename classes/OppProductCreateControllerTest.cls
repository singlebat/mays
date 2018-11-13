@isTest
public class OppProductCreateControllerTest {
    static testMethod void testOppProductCreate() {
    	
    	//すべてのテストデータを作成
    	createData();    	
    	
    	System.debug('Start testOppProductCreate');
    	
        Test.startTest();
        
        //初期化処理  初期化するとき、在庫の検索が要らない
        OppProductCreateController.initAction();
        
       //商品カテゴリ検索条件
        String categoryName = '';
        
        List<InventoryProduct__c> inpList=TestDataFactory.getInventoryProduct();
        inpList[0].specialFlg__c  = true;
        update inpList[0];
        system.debug('inpList:'+inpList);
        InventoryProduct__c invp=[SELECT Name FROM InventoryProduct__c WHERE ID=:inpList[0].Id];
        system.debug('Name:'+invp.Name);
        //その他の検索条件
        OppProductCreateController.SearchCondition sc = new OppProductCreateController.SearchCondition();
        sc.priceLowerLimit = null;
        sc.shortTerm = false;
        sc.specialFlg = true;

        String conditionArea= JSON.serialize(sc);
        List<String> currentStatus = new List<String>();
        List<String> rank = new List<String>();
        
        //検索ボタンを押して、検索処理を行う。
        List<OppProductCreateController.InventoryProductDetail> inventoryProductDetailList = OppProductCreateController.searchInventoryProduct(categoryName, conditionArea, currentStatus, rank);
        OppProductCreateController.setInventoryProducts(inpList);
        OppProductCreateController.doPackageProductSelect(invp.Name);
        //選択ボタンを押して、商品登録処理を行う
        String inventoryProductObj = JSON.serialize(inventoryProductDetailList[0]);
        OppProductCreateController.productSelected(inventoryProductObj, TestDataFactory.getLeaseEstimate()[0].id);
        //配送作成
        Delivery__c delivery = new Delivery__c(Estimate__c=TestDataFactory.getLeaseEstimate()[0].id,Agreement__c = TestDataFactory.getAgreements()[0].Id);
        insert delivery;
        inventoryProductDetailList[0].opportunityProductID = TestDataFactory.getOppProducts()[0].id;
		system.debug(TestDataFactory.getOppProducts()[0].id);
		system.debug(inventoryProductDetailList[0].opportunityProductID);
		//選択済ボタンを押して、商品削除処理を行う。        
        inventoryProductObj = JSON.serialize(inventoryProductDetailList[0]);
        system.debug(inventoryProductObj);
        //OppProductCreateController.deleteProduct(inventoryProductObj, TestDataFactory.getLeaseEstimate()[0].id);
        OppProductCreateController.doCreatePackage(TestDataFactory.getProductMaster()[0].id);
        OppProductCreateController.doDeletePackageProduct(inventoryProductObj);
        //OppProductCreateController.deleteProduct(inventoryProductObj, TestDataFactory.getLeaseEstimate()[0].id);
        
        Test.stopTest();
        
        System.debug('Stop testOppProductCreate');        
    }
    
    public static void createData() {
    	System.debug('Start');
    	TestDataFactory.createAllMstData();
/*    	
    	//設置場所マスタ
    	System.debug('設置場所マスタ:' + TestDataFactory.getInstallationLocation());
    	
	    //リース料率マスタ LeaseRateMaster__c
		System.debug('リース料率マスタ:' + TestDataFactory.getLeaseRateMaster());
		
		//仕入先
		System.debug('仕入先:' + TestDataFactory.getShireAccount());	
				
		//メーカーマスタ
		System.debug('メーカーマスタ:' + TestDataFactory.getMaker());
		
		//商品カテゴリマスタ
		System.debug('商品カテゴリマスタ:' + TestDataFactory.getProductCategory());
		
		//商品マスタ
		System.debug('商品マスタ:' + TestDataFactory.getProductMaster());
	
		//仕入別メーカー別マスタ
	    System.debug('仕入別メーカー別マスタ:' + TestDataFactory.getPurchaseProductMaster());
	    
	    //在庫
	    System.debug('在庫:' + TestDataFactory.getInventoryProduct());

	    //法人販売先
	    System.debug('法人販売先:' + TestDataFactory.getsalesHojinAccount());
	    
	    //商談
	    System.debug('商談:' + TestDataFactory.getOpportunity());
	    
	    //見積
	    System.debug('見積:' + TestDataFactory.getLeaseEstimate());
*/	    
        System.debug('End');
    }
}