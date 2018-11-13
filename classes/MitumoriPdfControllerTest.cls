@isTest
private class MitumoriPdfControllerTest extends CommonUntil{
    static testMethod void testMitumoriPdfController() {
        Test.startTest();
        createData();
		//PageReference pageMitumoriPDF=Page.MitumoriPDF;
		//Test.setCurrentPage(pageMitumoriPDF);
		//TestDataFactory.createAllMstData();
		//List<Opportunity> opps =TestDataFactory.getOpportunity(); 
		// Estimate__c mitum=new Estimate__c(CoordinationFee__c=12.0,DLFee__c=12.0,ShomeiToritsukeFee__c=12.0,Opportunity__c=opps[0].Id);
		// insert mitum;
         
         List<Estimate__c> mitumori1=TestDataFactory.getLeaseEstimate();
         //見積ステータスを「決定」に更新
         Estimate__c estimate = new Estimate__c(Id=mitumori1[0].id);
         estimate.QuotationStatus__c = '見積承認済';
         update estimate;
         //見積ID
         system.debug(estimate.id);
         ApexPages.currentPage().getParameters().put('id',estimate.id);
         ApexPages.currentPage().getParameters().put('modelNumberHide','true');
         //pageMitumoriPDF.getParameters().put('type',CommonUntil.MitumoriSho);
         //コントローラー開始
         MitumoriPdfController mitumori =new MitumoriPdfController();
         //pageMitumoriPDF.getParameters().put('type',CommonUntil.MitumoriDenpendSho);
         //MitumoriPdfController mitumori3 =new MitumoriPdfController();
         Test.stopTest();
    }
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}