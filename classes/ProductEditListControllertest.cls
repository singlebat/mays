@isTest
private class ProductEditListControllertest {
	static testMethod void testProductEditList() {
        Test.startTest();
        TestDataFactory.createAllMstData();
        Account accObj =  new Account(Name='テスト取引先2');
        insert accObj;
        // 商談
        Opportunity oppObj = new Opportunity(Name='商談', AccountId=accObj.Id, CloseDate=Date.today(), StageName='入客');
        insert oppObj;
        //契約
        Estimate__c estimate = TestDataFactory.getLeaseEstimate()[0];
        estimate.QuotationStatus__c = '見積承認済';
        update estimate;
        //estimate.QuotationStatus__c = '契約作成';
        //update estimate;
        Agreement__c agreement = new Agreement__c(Estimate__c=estimate.id);
        insert agreement;
        // 見積
        Estimate__c estimateObj = TestDataFactory.getLeaseEstimate()[0];
        
        ProductEditListController.getContractById(agreement.Id);
        String sortField = 'Rank__c';
        //設置場所
        InstallationLocation__c InstallationLocation = new InstallationLocation__c(Name='設置場所');
        insert InstallationLocation;
		//商品
        List<OpportunityProduct__c> oppProducts = TestDataFactory.getOppProducts();
        ProductEditListController.getWonProductById(estimateObj.Id,'Estimates__c');
        ProductEditListController.getInitInfo(estimateObj.Id,'Estimates__c');
        ProductEditListController.updateWonProduct(oppProducts);
        ProductEditListController.getRecordTypeId();
        ProductEditListController.deletedRecordById(oppProducts[0].Id);
        ProductEditListController.getInstallationLocations();
        Test.stopTest();
    }    
}