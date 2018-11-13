@isTest       
public with sharing  class PurchaseControllerTest {
    static testMethod void purchaseControllerTest(){
        Test.startTest();
        createData();
        Opportunity opp=TestDataFactory.getOpportunity()[0];

        //契約
        Agreement__c  Agreement = TestDataFactory.getAgreements()[0];
        
        //仕入
        List<Purchase__c> PurchaseList=new  List<Purchase__c>();
         for(Integer i=0;i<5;i++) {
            Purchase__c p = new Purchase__c(Suppliers__c=TestDataFactory.getShireAccount().Id,DeliveryTime2__c=System.today(),Status__c='発注済',
                                           Estimate__c=TestDataFactory.getLeaseEstimate()[0].Id);
            PurchaseList.add(p);
        }
        insert PurchaseList;
        
         List<Purchase__c> PurchaseList2=new  List<Purchase__c>();
         for(Integer i=0;i<5;i++) {
            Purchase__c p = new Purchase__c(Estimate__c=TestDataFactory.getLeaseEstimate()[0].Id ,Suppliers__c=TestDataFactory.getShireAccount().Id,DeliveryTime2__c=System.today(),Status__c='未発注');
            PurchaseList2.add(p);
        }
        insert PurchaseList2;
       
        PurchaseController.getPurchaseById(TestDataFactory.getLeaseEstimate()[0].Id);
        //PurchaseController.getPurchaseByAgreementId(Agreement.id);
        PurchaseController.updPurchaseList(PurchaseList,'Order');
        Test.stopTest();
    }
    
    public static void createData(){
        TestDataFactory.createAllMstData();
    }
}