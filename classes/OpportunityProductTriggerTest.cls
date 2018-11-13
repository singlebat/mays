@isTest
public class OpportunityProductTriggerTest {
    static testMethod void testOpportunityProductTrigger() {
        Test.startTest();
        createData();
        
        OpportunityProduct__c oppProduct = TestDataFactory.getOppProducts()[0];
        oppProduct.PurchaseStatus__c = '未発注';
        update oppProduct;
        //確認から発注済に変更
        oppProduct.PurchaseStatus__c = '発注済';
        update oppProduct;
        oppProduct.PurchaseStatus__c = '買取';
        update oppProduct;
        
        Estimate__c estimate = TestDataFactory.getLeaseEstimate()[0];
        List<OpportunityProduct__c> oppProducts = TestDataFactory.getOppProducts();
        Map<ID, OpportunityProduct__c> newMap = new Map<Id, OpportunityProduct__c>(oppProducts);
        OpportunityProductTriggerHandler.createProducts(oppProducts,estimate,newMap);
        
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}