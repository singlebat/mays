@isTest
private class SignedAgreementControllerTest {

    static testMethod void testSignedAgreementController() {
        // TO DO: implement unit test
        
        Test.startTest();
        createData();
        // 見積
        Estimate__c estimateObj = TestDataFactory.getLeaseEstimate()[0];
        SignedAgreementController.getInitInfo(estimateObj.Id);
        Account ac=TestDataFactory.getsalesHojinAccount()[0];
        SignedAgreementController.getAccoutInfoById(ac.Id);
        
        //ファイルアップロードテスト
        List<PayFile> fileList = new List<PayFile>();
        PayFile file1 = new PayFile();
        file1.name = 'file';
        //file1.content = EncodingUtil.base64Decode('ABC') + 'base64,' + EncodingUtil.base64Decode('EFG');
        file1.content = 'ABCbase64,EFG';
        fileList.add(file1);
        String files = JSON.serialize(fileList);
        
        SignedAgreementController.saveBatchFiles(files,estimateObj.Id);
        Test.stopTest();
    }
     public static void createData() {
        TestDataFactory.createAllMstData();
    }
}