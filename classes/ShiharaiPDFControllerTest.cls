@isTest
public with sharing class ShiharaiPDFControllerTest {
    static testMethod void testMethod1() {
        Test.startTest();
        TestDataFactory.createAllMstData();
        ApexPages.currentPage().getParameters().put('id',TestDataFactory.getAgreements()[0].Id);
        ShiharaiPDFController controller = new ShiharaiPDFController();
        Test.stopTest();
    }
}