@isTest
public with sharing class PurchasePdfControllerTest {
	static testMethod void testPurchasePdfController() {
        Test.startTest();
        createData();
        Opportunity opp=TestDataFactory.getOpportunity()[0];

        //契約
        Agreement__c  Agreement = TestDataFactory.getAgreements()[0];
        
        //仕入
        Datetime dateT = Datetime.now();
        Purchase__c p = new Purchase__c(Suppliers__c=TestDataFactory.getShireAccount().Id,DeliveryTime2__c=dateT,
                                        Estimate__c=TestDataFactory.getLeaseEstimate()[0].Id);   
        insert p;
        
        //商品カテゴリ 
        CustomObjectProductCategory__c pro= TestDataFactory.getProductCategory()[0];
        pro.costFlg__c=false;
        update  pro;
        
        //商品マスタ 
        CustomObjectProductMaster__c cus=TestDataFactory.getProductMaster()[0];
        cus.ProductCategory__c=pro.id;
        update cus;
        
        //商品       
        List <OpportunityProduct__c> product= TestDataFactory.getOppProducts();
        for(OpportunityProduct__c o:product){
           //商品マスタ親
           o.Product__c=cus.id;
           o.Purchase__c=p.Id;
        }
        update product; 
        
        PageReference MitumoriDepend=Page.MitumoriDependPDF;
        Test.setCurrentPage(MitumoriDepend);
        MitumoriDepend.getParameters().put('id',p.id);
        MitumoriDepend.getParameters().put('deliveryTime2',String.valueOf(DateTime.now()));      
        
        PurchasePdfController pu=New PurchasePdfController();
        Test.stopTest();
    }
	
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}