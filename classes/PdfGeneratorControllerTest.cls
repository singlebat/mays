@isTest
public class PdfGeneratorControllerTest {
    static testMethod void testMethod1(){
         Test.startTest();
         TestDataFactory.createAllMstData();
         List<Estimate__c> mitumori = TestDataFactory.getLeaseEstimate();
         Agreement__c agc=TestDataFactory.getAgreements()[0];
         PdfGeneratorController.getInitInfo(mitumori[0].id,'Estimate__c');
         PdfGeneratorController.getPurchaseById(TestDataFactory.getPurchases()[0].id);
         PdfGeneratorController.savePDFCommon(mitumori[0].id,'Contract',mitumori[0].id);
         PdfGeneratorController.savePDFCommon(mitumori[0].id,'Oboegaki',mitumori[0].id);
         
         PdfGeneratorController.savePDFENGCommon(mitumori[0].id,'Contract',mitumori[0].id);
         PdfGeneratorController.savePDFENGCommon(mitumori[0].id,'Oboegaki',mitumori[0].id);
         
         //解約精算書
         PdfGeneratorController.updateForKaiyakuPDF(agc,'日本語');
         PdfGeneratorController.createKaiyakuOrLTConfirmPDF(agc.id,agc.id,'Kaiyaku','日本語');
         
         //見積書
         //mitumori[0].EstimateLanguage__c='英語';
         //update mitumori[0];
         PdfGeneratorController.updateForMitumoriPDF(mitumori[0].id,mitumori[0].id,true,true,true,true,true,'日本語');
         PdfGeneratorController.createMitumoriPDFBatch(mitumori[0].id,mitumori[0].id);
         //リース満了期間通知書
         PdfGeneratorController.updateForLeaseTermConfirmPDF(agc.id,'日本語',false);

         agc.Status__c = '契約済';
         update agc;
         //請求明細作成
         PdfGeneratorController.createBillDetail('Estimate__c',mitumori[0].id,'日本語');
         PdfGeneratorController.createBillDetail('',agc.id,'日本語');
         //請求書作成
         PdfGeneratorController.createInvoicePDF('Estimate__c',mitumori[0].id,'日本語');
         PdfGeneratorController.createInvoicePDF('',agc.id,'日本語');
         //一括請求
         PdfGeneratorController.saveAllBillDetail('2018','12','振込','一致する','20',TestDataFactory.getsalesHojinAccount()[0].Id,TestDataFactory.getAgreements()[0].Id);
         PdfGeneratorController.createInvoiceMutiPDF('2018','12','振込','一致する','20',TestDataFactory.getsalesHojinAccount()[0].Id,TestDataFactory.getAgreements()[0].Id);
         
         agc.Status__c = '契約解除待ち';
         update agc;

         //請求書且契約作成
         PdfGeneratorController.saveKeiyakuAndInvoicePDF(mitumori[0].id,mitumori[0].id,'リース');
         //保証金返金とダメージ料金
         PdfGeneratorController.saveHosyokinAndDamage(agc.id,true,true);
         
         PdfGeneratorController.updPurchaseList(TestDataFactory.getPurchases(),'Order',mitumori[0].id,'日本語');
         mitumori[0].QuotationStatus__c='決定';
         PdfGeneratorController.Request re =new PdfGeneratorController.Request();
         re.sObjId=mitumori[0].id;
         re.SobjType='Estimate__c';
         List<PdfGeneratorController.Request> requests =new List<PdfGeneratorController.Request>();
		 requests.add(re);
         update mitumori[0];
         PdfGeneratorController.PDFAutomaticallyCreate(requests);
         re.sObjId=agc.id;
         re.SobjType='Agreement__c';
         requests.add(re);
         agc.Status__c = '契約済';
         update agc;
         agc.Status__c = '契約更新手続き中';
         update agc;
         PdfGeneratorController.PDFAutomaticallyCreate(requests);
         PdfGeneratorController.createInvProducts(mitumori[0]);
         
         ApexPages.currentPage().getParameters().put('id',agc.id);
         hosyoukinController con = new hosyoukinController();
         Test.stopTest();
    }
}