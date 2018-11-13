@isTest
public class LookupFieldControllerTest {
    static testMethod void testLookupField() {
        Test.startTest();
        createData();
        //LookupFieldController.obtainObjectList('AA','ACCOUNT');
        LookupFieldController.obtainObjectById(TestDataFactory.getOpportunity()[0].Id,'Opportunity');
        LookupFieldController.getInfo('ACCOUNT');
        //LookupFieldController.showRecentViewed('ACCOUNT');
        LookupFieldController.runQuery('ACCOUNT','ACCOUNT',false);
        LookupFieldController.runQuery('case','case',false);
        LookupFieldController.runQuery('contract','contract',false);
        LookupFieldController.obtainObjectList('contract','contract','');
        Test.stopTest();
    }
    
    public static void createData() {
        TestDataFactory.createAllMstData();
    }
}