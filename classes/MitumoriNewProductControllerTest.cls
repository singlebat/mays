@isTest
public class MitumoriNewProductControllerTest {
	
    static testMethod void testMethod1() {
    	//すべてのテストデータを作成
    	createData();

		System.debug('Start testOppProductCreate');
        Test.startTest();
		OpportunityProduct__c op=TestDataFactory.getOppProducts()[0];
		op.ProductType__c = '仕入品';
		update op;
		MitumoriNewProductController.updateInvOppProducts(op.id);
		MitumoriNewProductController.createInvOppProducts(op.id);
    	MitumoriNewProductController.getProductMasterInfo(TestDataFactory.getProductMaster()[0].id);
    	MitumoriNewProductController.initEdit(op.id);
    	MitumoriNewProductController.getPurchaseProductMasterInfo(TestDataFactory.getProductMaster()[0].id,TestDataFactory.getPurchaseProductMaster()[0].id);
    	Test.stopTest();
    	
        System.debug('Stop testOppProductCreate');       
    }
    
    public static void createData() {
    	TestDataFactory.createAllMstData();
    }
    
}