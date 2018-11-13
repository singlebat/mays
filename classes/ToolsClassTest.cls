@isTest
private class ToolsClassTest {

    static testMethod void testMethod1() {
        Test.startTest();
        ToolsClass.getCommonRate('testテストtestテストtestテスト',13,43.5,2);        
        ToolsClass.kaigyo('fsadfsadfsdafadsfdsafasfdas',3);
        ToolsClass.getHtmlSpanStrByRate('fsadfsadfsdafadsfdsafasfdas',13.0,43.5,2.0);
        Test.stopTest();
    }
}