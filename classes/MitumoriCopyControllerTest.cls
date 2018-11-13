@isTest
public class MitumoriCopyControllerTest {
    static testMethod void testMitumoriCopy() {
        Test.startTest();
        createData();
        //OpportunityProduct__c oppProduct = new OpportunityProduct__c(Estimates__c = TestDataFactory.getLeaseEstimate()[0].Id);
        //insert oppProduct;
        
        //InventoryOpportunityProduct__c invOppProduct= new InventoryOpportunityProduct__c(OpportunityProduct__c = oppProduct.Id);
        //insert invOppProduct;
        //配送作成
        Delivery__c delivery = new Delivery__c(Estimate__c=TestDataFactory.getLeaseEstimate()[0].Id,Agreement__c = TestDataFactory.getAgreements()[0].Id);
        insert delivery;
        List<EstimateNumber__c> estimateNum1=[select id,EstimateSerialNum__c from EstimateNumber__c];
        if(estimateNum1.size() == 0){
	        EstimateNumber__c estimateNum = new EstimateNumber__c(EstimateSerialNum__c=1);
	        insert estimateNum;
        }
        MitumoriCopyController.copy(TestDataFactory.getLeaseEstimate()[0].Id,'new');
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}