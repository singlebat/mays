@isTest
private class PaymentInputControllerTest {

    static testMethod void testPaymentInputController() {
        // TO DO: implement unit test
        Test.startTest();
        createData();
        
        List<Account> ac=TestDataFactory.getsalesHojinAccount();
        ac[0].Bank_account_Nominee__c = 'BRODRICK MATTHEW';
        ac[0].Financial_Name__c= 'SMBCｼﾝ';
        ac[0].Financial_branch__c= 'ﾋﾛｵ';
        update ac[0];
        String files='[{	"name":"furinyu2.csv",'+
        				'"content":"1,1,0,300124,300104,300124,9,ﾐﾂｲｽﾐﾄﾓ,654,ｼﾌﾞﾔ,2,5007402,ｶ) ﾒｲｽﾞ,\\r\\n2,999999999,300110,300110,1000,0,,BRODRICK MATTHEW,SMBCｼﾝ,ﾋﾛｵ,,, ,\\r\\n8,58,10038713,0,0, ,,,,,,,,\\r\\n9, ,,,,,,,,,,,,\\r\\n",'+
						'"isShowIcon":true,'+
						'"size":4058}]';
        system.debug(files);
        
        List<BilledDetail__c> bdc=TestDataFactory.getBilledDetails();
        bdc[0].MonthlyLeaseFee__c  =2000;
        update bdc[0];
        PaymentInputController.saveBatchFiles(files);
       
        Test.stopTest();
    }
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}