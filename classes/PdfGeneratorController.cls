/** 
 * PDF印刷メイン処理
 */
public class PdfGeneratorController {
    /** 
     * 納期確認及び見積依頼書 : 仕入先表示リスト
     */ 
    public class Purchase {
        /**
         * 選択フラグ
         */
        @AuraEnabled
        public boolean selectedFlg;
        
        /**
         * 仕入オブジェクト
         */
        @AuraEnabled
        public Purchase__c purchaseObj {get;set;}
    }
    
     public class PDFClass {

        @AuraEnabled
        public Estimate__c ec;

        @AuraEnabled
        public Agreement__c ag;
    }
    
    //PDF印刷画面初期化処理
    @AuraEnabled
    public static PDFClass getInitInfo(String Id,String sobName){
    	PDFClass pd= new PDFClass();
    	if(sobName=='Estimate__c'){
        	pd.ec= CommonUntil.getEstimateById(Id);
    	}else{
    		pd.ag=[SELECT Estimate__r.EstimateLanguage__c,Estimate__r.MonthlyPrintFlag__c FROM Agreement__c WHERE id=:Id];
    	}
    	return pd;
    }
    
    /** 
     * 納期確認及び見積依頼書 || 注文書 : 仕入先表示リストの取得
     */
    @AuraEnabled
    public static List<Purchase> getPurchaseById(String Id){
        System.debug('PdfGeneratorController getPurchaseById: ' + Id);
        
        //仕入先リストを取得
        List<Purchase__c> purchaseList = PurchaseController.getPurchaseById(Id);
        
        List<Purchase> purchaseWithSelectList = new List<Purchase>();
        //退避処理
        for (Purchase__c purchase : purchaseList) {
            Purchase pss = new Purchase();
            pss.selectedFlg = true;
            pss.purchaseObj = purchase;
            purchaseWithSelectList.add(pss);
        }
        System.debug('purchaseWithSelectList: ' + purchaseWithSelectList);

        return purchaseWithSelectList;      
    }
    
    /** 
     * 仕入の納入日,納入時刻を更新、PDFを印刷
     */
    @AuraEnabled
    public static List<String> updPurchaseList(List<Purchase__c> purchaseList, String pdfType ,String id,String language){
    	List<String> idList= new List<String>();
        System.debug('PdfGeneratorController purchaseList: ' + purchaseList);
        System.debug('pdfType: ' + pdfType);
		
        //仕入の納入日,納入時刻を更新
        PurchaseController.updPurchaseList(purchaseList,pdfType);
        
        //納期確認及び見積依頼書 || 注文書 PDFを印刷
        for(Purchase__c purchase: purchaseList){
        	system.debug('purchase.bikou__c:::' + purchase.bikou__c);
            String documentid=savePdfForMitumoriDepend(purchase.Id, purchase.Suppliers__r.Name, pdfType, id ,
                                     String.valueOf(purchase.DeliveryTime2__c),
                                     purchase.bikou__c != null ? purchase.bikou__c.replaceAll('\r\n','<br/>') : purchase.bikou__c,
                                     purchase.HaisouType__c,
                                     purchase.ShippingCost__c,
                                     language);       
           idList.add(documentid);
        }
        return idList;
    }
    
    /** 
     * 納期確認及び見積依頼書 或は 注文書
     * purchaseId 仕入ID
     * name 仕入先名前
     * pdfType 納期確認及び見積依頼書
     * id 見積ID
     * deliveryTime2 納入日
     * bikou 備考
     */
    @AuraEnabled
    public static String savePdfForMitumoriDepend(String purchaseId, String name, String pdfType ,String id ,String deliveryTime2,String bikou,String haisouType,Decimal shippingCost,String language){ 
    	System.debug('bikou: ' + bikou);
        String title;
        PageReference pageRef ;
        if(language=='日本語'){
        	pageRef= Page.MitumoriDependPDF;
        }else{
        	pageRef= Page.MitumoriDependEngPDF;
        }
        updateEstimateLanguage(id,language);
        
		//英語のタイトルがないため、今は全部日本語です
        if(pdfType == 'Order'){//注文書の場合
            title = CommonUntil.ChiyumanSho + '_' + name + '_' + haisouType;
        }else{//納期確認及び見積依頼書の場合
            title=CommonUntil.MitumoriDenpendSho + '_' + name + '_' + haisouType;
        }                
        pageRef.getParameters().put('id', purchaseId );
        pageRef.getParameters().put('pdfType', pdfType );
        pageRef.getParameters().put('deliveryTime2', deliveryTime2 );
        pageRef.getParameters().put('bikou', bikou );
        pageRef.getParameters().put('shippingCost', String.valueOf(shippingCost) );
        //ファイルの作成
        return createPdfFile(pageRef, title ,id);      
    }
    
    /** 
     * 一括請求明細を作成
     */
    @AuraEnabled 
    public static void saveAllBillDetail(String year,String month,String PaywayValue,String localValue,String day,String request,String questionNO){
    	//請求と請求明細を作成する 
    	CreateAllMultipleBilled.createAllBilled(year,month,PaywayValue,localValue,day,request,questionNO);
    }
    
    /** 
     * 一括請求書PDFを印刷
     */
    @AuraEnabled
    public static List<String> createInvoiceMutiPDF(String year,String month,String PaywayValue,String localValue,String day,String request,String questionNO){
    	//請求明細IDSを取得する 
    	List<Id> BilledDetailIdList = CreateAllMultipleBilled.getAllBilledDetailIds(year,month,PaywayValue,localValue,day,request,questionNO);
    	system.debug(BilledDetailIdList);
    	if (BilledDetailIdList.size() > 0) {
    	    String BilledDetailIds = String.join(BilledDetailIdList,',');
            //PDFを作成する
            String title = CommonUntil.Invoice;
            PageReference pageRef= Page.InvoiveMutiPDF;
            //請求明細集合
            pageRef.getParameters().put('year',year);
            pageRef.getParameters().put('month',month);
            pageRef.getParameters().put('PaywayValue',PaywayValue);
            pageRef.getParameters().put('localValue',localValue);
            pageRef.getParameters().put('day',day);
            pageRef.getParameters().put('request',request);
            pageRef.getParameters().put('questionNO',questionNO);
            //ファイルの作成   
            DateTime dt = System.now();
            dt.addHours(9);
            String dateTimeStr = dt.format('yyMMdd');
            ContentVersion conObject=new ContentVersion();
            conObject.title=title+'_' + dateTimeStr +'.pdf';
            conObject.PathOnClient=title + dateTimeStr+'.'+'pdf' ;
            conObject.ContentUrl='';
            try{
                conObject.versiondata=pageRef.getContent();
            }catch (VisualforceException e) {
                conObject.versiondata = Blob.valueOf('Some Text');
            }
            // メモ&添付INSERT
            insert conObject;
            //ContentVersionの関連を確立
            ContentVersion conObjectTemp = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id =: conObject.Id];
            // ChatterGroup取得
            String groupName='請求グループ';
		    List<CollaborationGroup> objCollaborationGroups = [select Id ,Name from CollaborationGroup where Name =: groupName limit 1];
		    if (objCollaborationGroups.size() > 0) {
		        // レコードのChatterを作成する
                FeedItem contentFI = new FeedItem();
                contentFI.Type = 'ContentPost';
                contentFI.ParentId = objCollaborationGroups[0].id;
                contentFI.RelatedRecordId = conObject.id;
                contentFI.Body = title + 'を作成する';
                insert contentFI;
		    }
            
            List<String> idList= new List<String>();
            idList.add(conObjectTemp.ContentDocumentId);
            
            updateBillDetail(BilledDetailIdList,Date.newInstance(Integer.valueOf(year),Integer.valueOf(month),1));
            return idList;
    	}
    	
    	return null;
    }
    
    /** 
     * 印刷後、請求明細の「請求書作成年月」を更新
     */
    @future (callout=true)
    public static void updateBillDetail(List<Id> BilledDetailIdList , Date BilledDate){
    	List<BilledDetail__c> billedDetailList = new List<BilledDetail__c>();
    	for (Id id : BilledDetailIdList) {
    		BilledDetail__c BilledDetail = new BilledDetail__c();
    		BilledDetail.Id = id;
    	    BilledDetail.CreateBilledDate__c = BilledDate;
    	    billedDetailList.add(BilledDetail);
    	}
    	update billedDetailList;
    }

    /** 
     * 画面から印刷するとき、請求・請求明細(リース、販売)を再作成
     */
    @AuraEnabled
    public static void createBillDetail(String sObjectName ,String id, String language){

        if(sObjectName == 'Estimate__c'){
        	updateEstimateLanguage(id,language);
            Estimate__c mitumori = CommonUntil.getEstimateById(id);
            //請求・請求明細を再作成
            if(mitumori.RecordType.Name == 'リース'){
	    	    CreateMultipleBilled.createBilledByAgreementId(mitumori.Estimate__r[0].Id);
            } else {
                CreateMultipleSalesBilled.createBilledByAgreementId(mitumori.Estimate__r[0].Id,'販売');
            }
        }else{
        	Agreement__c agreement = getAgreementById(id);
            updateEstimateLanguage(agreement.Estimate__c,language);
        	//請求・請求明細を再作成
	    	CreateMultipleSalesBilled.createBilledByAgreementId(id,'販売');
        }
    }
    
    /** 
     * 請求書PDFを印刷(画面から手動で)
     */
    @AuraEnabled
    public static List<String> createInvoicePDF(String sObjectName ,String id , String language){
    	List<String> idList= new List<String>();
        PageReference pageRef= null;
        
        if(sObjectName == 'Estimate__c'){
            Estimate__c mitumori = CommonUntil.getEstimateById(id);
            if(mitumori.RecordType.Name=='リース'){
        	    if (language == '日本語') {
        	        pageRef= Page.InvoicePDF;
        	    } else {
        	        pageRef= Page.InvoiceEngPDF;
        	    }
            }else if(mitumori.RecordType.Name=='販売'){
        	    pageRef= Page.InvoiceSalesPDF;
            }        
	        pageRef.getParameters().put('id', mitumori.Estimate__r[0].Id );
        }else{
        	if (language == '日本語') {
        	    pageRef= Page.InvoicePDF;
        	} else {
        	    pageRef= Page.InvoiceEngPDF;
        	}
        	pageRef.getParameters().put('id', id );
        }
        
        //ファイルの作成
        String documentID=createPdfFile(pageRef, CommonUntil.Invoice ,id);
        idList.add(documentID);
        return idList;
    }
    
    /** 
     * 御見積書の場合
     * id id
     * pdfType 御見積書
     * linkedId リンクされているオブジェクトID
     * modelNumberHide 型番非表示
     */
    @AuraEnabled
    public static void updateForMitumoriPDF(String id, String linkedId,Boolean modelNumberHide,
    										Boolean truckCancelHide,Boolean newAgreemntHide,Boolean hatyuNyukinHide,Boolean furikomiKozaHide,
    										String language){ 
        Estimate__c mitumori = new Estimate__c();
        mitumori.Id = id;
        mitumori.ModelNumberHide__c = modelNumberHide;
        mitumori.TruckCancelFlag__c = truckCancelHide;
        mitumori.NewAgreemntFlag__c = newAgreemntHide;
        mitumori.HatyuNyukinFlag__c = hatyuNyukinHide;
        mitumori.FurikomiKozaFlag__c = furikomiKozaHide;
        mitumori.EstimateLanguage__c = language;
        update mitumori;
    }
    
    /** 
     * 御見積書を作成する
     * id id
     * linkedId リンクされているオブジェクトID
     */
    @AuraEnabled
    public static List<String> createMitumoriPDF(String id ,String linkedId){ 
    	List<String> idList= new List<String>();
        Estimate__c mitumori = [SELECT SubTitle__c,EstimateLanguage__c,QuotationType__c,QuotationSalesType__c,RecordType.Name FROM Estimate__c WHERE id=: id];
        
        PageReference pageRef= null;
        String title;
        if(mitumori.EstimateLanguage__c == '日本語'){
	        if(mitumori.RecordType.Name=='リース'){
	        	if(mitumori.QuotationType__c=='概算見積書'){
	        		pageRef= Page.MitumoriGaisanPDF;
	        	}else{
	        		pageRef= Page.MitumoriPDF;
	        	}
	        }else if(mitumori.RecordType.Name=='販売'){
	        	pageRef= Page.MitumoriSalesPDF;
	        }
        	title = CommonUntil.MitumoriSho + (mitumori.SubTitle__c == null ? '' : '_' + mitumori.SubTitle__c);
        }else if(mitumori.EstimateLanguage__c == '英語'){
        	if(mitumori.RecordType.Name=='リース'){
	        	pageRef= Page.MitumoriEngPDF;
	        }else if(mitumori.RecordType.Name=='販売'){
	        	pageRef= Page.MitumoriSalesPDF;
	        }
        	title = CommonUntil.MitumoriShoENG + (mitumori.SubTitle__c == null ? '' : '_' + mitumori.SubTitle__c);
        }
        //パラメータの設定
        pageRef.getParameters().put('id', id );
        //ファイルの作成
        String documentID=createPdfFile(pageRef, title ,linkedId);
        idList.add(documentID);
        return idList;
    }

    /** 
     * 見積の言語を更新
     * id 見積ID
     * language 英語または日本語
     */
    @AuraEnabled
    public static void updateEstimateLanguage(String id, String language){ 
    	Estimate__c ec = [SELECT EstimateLanguage__c FROM Estimate__c WHERE id=: id];
    	if (ec.EstimateLanguage__c != language) {
    	    Estimate__c mitumori = new Estimate__c();
            mitumori.Id = id;
            mitumori.EstimateLanguage__c = language;
            update mitumori;
    	}
    }
    
    /** 
     * 解約精算確認書印刷前の更新
     * agreement 更新オブジェクト
     * language 英語または日本語
     */
    @AuraEnabled
    public static void updateForKaiyakuPDF(Agreement__c agreement,String language){
    	if (agreement.Status__c == '契約済') {    //契約済みの場合：契約ステータス変更
            agreement.Status__c = '契約更新手続き中';
            agreement.ExpirationOrCancell__c = '途中解約';
        }
        update agreement;
        updateEstimateLanguage(agreement.Estimate__c,language);
    }
    
    /** 
     * 解約精算確認書、リース満了期間通知書の印刷
     * agreement 更新オブジェクト
     * language 英語または日本語
     */
    @AuraEnabled
    public static List<String> createKaiyakuOrLTConfirmPDF(Id aggrementId, ID linkedId , String pdfType,String language){ 
    	List<String> idList= new List<String>();
        if(language == '日本語'){
            idList = savePDFCommon(aggrementId, pdfType,linkedId);
        }else{
            idList = savePDFENGCommon(aggrementId, pdfType,linkedId);
        }
        return idList;
    }
    
    /** 
     * リース満了期間通知書印刷前の更新
     * id 更新id
     * language 言語
     * updateFlg 更新進めるかどうかフラグ
     */
    @AuraEnabled
    public static void updateForLeaseTermConfirmPDF(String id,String language,Boolean updateFlg){
        Agreement__c agreement = getAgreementById(id);
        updateEstimateLanguage(agreement.Estimate__c,language);
        if (!agreement.LeaseTermEndFlg__c) {
            agreementInfoUpdate(agreement);
        }
        if (agreement.Status__c == '契約済' && updateFlg) {    //契約済みの場合：契約ステータス変更、プロセスビルダよりPDFAutomaticallyCreateをcallして、リース満了期間通知書を出力する。
            agreement.Status__c = '契約更新手続き中';
            agreement.ExpirationOrCancell__c = '満了';
            update agreement;
        }
    }

    /** 
     * リース満了期間通知書印刷前の更新メイン処理
     */
    @AuraEnabled
    public static void agreementInfoUpdate(Agreement__c agreement){
        //契約 契約終了後の販売率、(非表示)更新後月額リース料率1、(非表示)更新後月額リース料率2、更新後月額リース料率、買取請求先(契約者)、買取請求先(使用者)
        agreement.ContractEndSellingRate__c = agreement.Estimate__r.LeaseTerm__r.ContractEndSellingRate__c;
        agreement.MonthlyLeaseRateForUpd1__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate1__c;
        agreement.MonthlyLeaseRateForUpd2__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate2__c;
        agreement.NextLeaseStartHope__c = agreement.NextLeaseStart__c;
        agreement.NextLeaseEndHope__c = agreement.NextLeaseEnd__c;
        if (agreement.UpdateCnt__c == 0 ) {
            agreement.MonthlyLeaseRateForUpd__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate1__c;
        } else {
            agreement.MonthlyLeaseRateForUpd__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate2__c;
        }
        //リース期間満了印刷済フラグTRUEにする。
        agreement.LeaseTermEndFlg__c = true;
        
        update agreement;
        
        //在庫案件商品 契約終了後の販売率、(非表示)更新後月額リース料率1、(非表示)更新後月額リース料率2、更新後月額リース料率
        for (InventoryOpportunityProduct__c invOppProduct : agreement.InventoryOpportunityProduct__r) {
            if (!invOppProduct.ProductFlag__c) {
                invOppProduct.MonthlyLeaseRateForUpd1__c = 0;
                invOppProduct.MonthlyLeaseRateForUpd2__c = 0;
                invOppProduct.ContractEndSellingRate__c = 0;
                invOppProduct.MonthlyLeaseRateForUpd__c = 0;
            } else {
                invOppProduct.ContractEndSellingRate__c = agreement.Estimate__r.LeaseTerm__r.ContractEndSellingRate__c;
                invOppProduct.MonthlyLeaseRateForUpd1__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate1__c;
                invOppProduct.MonthlyLeaseRateForUpd2__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate2__c;
                 if (agreement.UpdateCnt__c == 0 ) {
                    invOppProduct.MonthlyLeaseRateForUpd__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate1__c;
                 } else {
                    invOppProduct.MonthlyLeaseRateForUpd__c = agreement.Estimate__r.LeaseTerm__r.PostRenewalRate2__c;
                }
            }
        }
        update agreement.InventoryOpportunityProduct__r;
    }
    
    /** 
     * 支払予定明細を作成
     * id id
     * pdfType Shiharai
     * linkedId リンクされているオブジェクトID
     * language 英語または日本語
     */
    @AuraEnabled
    public static void createPaymentDetailsForShiharaiPDF(String id ,String language){
    	Agreement__c agreement = getAgreementById(id);
    	updateEstimateLanguage(agreement.Estimate__c,language);
        //支払予定明細の作成
        AgreementTriggerHandler.paymentDetailsCreate(agreement);
    }
    
    /** 
     * 支払予定表作成
     * linkedId 紐づけオブジェクトID
     * pdfType PDF種類
     * aggrementId 更新ID
     * 仕組み：バッチ処理
     */
    @AuraEnabled
    public static List<String> createShiharaiPDF(Id aggrementId, ID linkedId , String pdfType,String language) {
    	List<String> idList= new List<String>();
        if(language=='日本語'){
            idList=savePDFCommon(aggrementId, pdfType,linkedId);
        }else{
            idList=savePDFENGCommon(aggrementId, pdfType,linkedId);
        }
        return idList;
    }

    /** 
     * PDF印刷処理
     * id オブジェクトID
     * pdfType 見積書:mitumori 印刷するPDF種類
     * linkedId リンクされているオブジェクトID
     */
    @AuraEnabled
    public static List<String> savePDFCommon(String id, String pdfType ,String linkedId){
    	List<String> idList= new List<String>();
        System.debug('PdfGeneratorController savePdf Id :' + id);
        String title;
        PageReference pageRef = null;    
        if(pdfType =='Contract'){//契約書の場合
            pageRef = Page.keiyakuPDF;
            title = CommonUntil.Contract;
            pageRef.getParameters().put('pdfType', pdfType );
            pageRef.getParameters().put('type',CommonUntil.Contract);
        } else if(pdfType == 'Shiharai'){//お支払い予定表
            pageRef = Page.ShiharaiPDF;
            title = CommonUntil.Shiharai;
        } else if(pdfType == 'LeaseTermConfirm'){//リース満了期間通知書の場合
            pageRef = Page.kikankanrxyouPDF;
            title = CommonUntil.LeaseTermConfirm;
            pageRef.getParameters().put('pdfType', pdfType );
        } else if(pdfType == 'Kaiyaku'){//解約精算確認書の場合
            pageRef = Page.kikankanrxyouPDF;
            title = CommonUntil.Kaiyaku;
            pageRef.getParameters().put('pdfType', pdfType );
        } else if(pdfType == 'Oboegaki'){//覚書の場合
            pageRef = Page.keiyakuPDF;
            title = CommonUntil.Memorandum;
            pageRef.getParameters().put('pdfType', pdfType );
            pageRef.getParameters().put('type',CommonUntil.Memorandum);
        } else if(pdfType == 'Hosyokin'){//保証金返金の場合
            pageRef = Page.hosyoukinPDF;
            title = CommonUntil.Hosyoukin;
        }

        //パラメータの設定
        pageRef.getParameters().put('id', id );
        //ファイルの作成
        String documentId=createPdfFile(pageRef, title ,linkedId);
        idList.add(documentId);
        return idList;
    }
    
    /** 
     * PDF印刷処理（ENGLISH）
     * id オブジェクトID
     * pdfType 見積書:mitumori 印刷するPDF種類
     * linkedId リンクされているオブジェクトID
     */
    @AuraEnabled
    public static List<String>  savePDFENGCommon(String id, String pdfType ,String linkedId){
    	List<String> idList= new List<String>();
        System.debug('PdfGeneratorController savePdf Id :' + id);
        String title;
        PageReference pageRef = null;    
        if(pdfType =='Contract'){//契約書の場合
            pageRef = Page.keiyakuEngPDF;
            title = CommonUntil.Contract;
            pageRef.getParameters().put('pdfType', pdfType );
            pageRef.getParameters().put('type',CommonUntil.Contract);
        } else if(pdfType == 'Shiharai'){//お支払い予定表
            pageRef = Page.ShiharaiENGPDF;
            title = CommonUntil.Shiharai;
        } else if(pdfType == 'LeaseTermConfirm'){//リース満了期間通知書の場合
            pageRef = Page.kikankanrxyouENGPDF;
            title = CommonUntil.LeaseTermConfirm;
            pageRef.getParameters().put('pdfType', pdfType );
        } else if(pdfType == 'Kaiyaku'){//解約精算確認書の場合
            pageRef = Page.kikankanrxyouENGPDF;
            title = CommonUntil.Kaiyaku;
            pageRef.getParameters().put('pdfType', pdfType );
        } else if(pdfType == 'Oboegaki'){//覚書の場合
            pageRef = Page.keiyakuEngPDF;
            title = CommonUntil.Memorandum;
            pageRef.getParameters().put('pdfType', pdfType );
            pageRef.getParameters().put('type',CommonUntil.Memorandum);
        } else if(pdfType == 'Hosyokin'){//保証金返金の場合
            pageRef = Page.HosyoukinEngPDF;
            title = CommonUntil.Hosyoukin;
        }
        
        //パラメータの設定
        pageRef.getParameters().put('id', id );
        //ファイルの作成
        String documentId=createPdfFile(pageRef, title ,linkedId);
        idList.add(documentId);
        return idList;
    }
   /** 
     * ContentVersion保存の公用方法(ファイルの作成)
     * id id
     */     
    private static String createPdfFile(PageReference pageRef, String title ,String linkedId ){
    	String documentID;
        DateTime dt = System.now();
        system.debug(dt);
        dt.addHours(9);
        String dateTimeStr = dt.format('yyMMdd');
        ContentVersion conObject=new ContentVersion();
        conObject.title=title+'_' + dateTimeStr +'.pdf';
        conObject.PathOnClient=title + dateTimeStr+'.'+'pdf' ;
        conObject.ContentUrl='';
        try{
            conObject.versiondata=pageRef.getContent();
        }catch (VisualforceException e) {
            conObject.versiondata = Blob.valueOf('Some Text');
        }
        // メモ&添付INSERT
        system.debug(conObject);
        insert conObject;
        
        //ContentVersionの関連を確立
        ContentVersion conObjectTemp = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id =: conObject.Id];
        insert new ContentDocumentLink(LinkedEntityId=linkedId,ContentDocumentId=conObjectTemp.ContentDocumentId,ShareType='V');
        documentID=conObjectTemp.ContentDocumentId;
        return documentID;
    }
    
    public class Request {
        @InvocableVariable(required=true)
        public ID sObjId;
        @InvocableVariable(required=true)
        public String SobjType;
    }
    
    /** 
     * 承認プロセスより、承認後PDF自動作成
     * requests オブジェクトIDとTypeリスト
     */
    @InvocableMethod(label='PDFAutomaticallyCreate')
    public static void PDFAutomaticallyCreate(List<Request> requests) {
        system.debug('PDF自動作成開始');
        system.debug(requests);
        for (Request request : requests) {
            if (request.SobjType == 'Estimate__c') {
                Estimate__c mitumori = CommonUntil.getEstimateById(request.sObjId);
                Agreement__c agreement = getAgreementById(mitumori.Estimate__r[0].Id);
                if(mitumori.RecordType.Name != '販売' && mitumori.QuotationStatus__c != '契約済'){
                	//支払予定明細の作成
                    AgreementTriggerHandler.paymentDetailsCreate(agreement);
                    //支払予定表作成
                	createShiharaiPDFBatch(agreement.Id , request.sObjId ,'Shiharai',mitumori.EstimateLanguage__c);
                }
                
                if (mitumori.QuotationStatus__c == '見積承認済') {
                    //在庫-見積、配送、有効期限、HOLD担当の更新
                    MitumoriTriggerHandler.updateInvProductHoldInfo(mitumori);
                    //見積書
                    createMitumoriPDFBatch(request.sObjId,request.sObjId);
                } else if (mitumori.QuotationStatus__c == '契約済') {
                	//在庫を作成する。
	                createInvProducts(mitumori);
                } else if (mitumori.QuotationStatus__c == '成約') {
                	//請求・請求明細を作成
	                if (mitumori.RecordType.Name == '販売') {
	                    CreateMultipleSalesBilled.createBilledByAgreementId(agreement.Id,'販売');
	                } else {
	                    CreateMultipleBilled.createBilledByAgreementId(agreement.Id);
	                }
                    //契約書且請求書 作成
                    saveKeiyakuAndInvoicePDF(request.sObjId,agreement.Id,mitumori.RecordType.Name);
                }
            } else {
                Agreement__c agreement = getAgreementById(request.sObjId);
                system.debug(agreement);
                if ((agreement.Status__c == '契約解除待ち'  || agreement.Status__c == '契約更新済') && agreement.ApprovalStatus__c =='申請提出' ) {
                	//if (agreement.ProductKaitoriCnt__c > 0 || agreement.TotalFee__c > 0) {
                	if (agreement.SeikyuPDF__c) {
                	    //請求・請求明細を作成
	                    //CreateMultipleBilled.createBilledByAgreementId(request.sObjId,'保証金');
	                    CreateMultipleSalesBilled.createBilledByAgreementId(request.sObjId,'保証金');
                	}
                	
                    //保証金返金とダメージ料金
                    saveHosyokinAndDamage(request.sObjId, agreement.HosyokinPDFFlag__c ,agreement.SeikyuPDF__c);
                }
            }
        }
    }
    
    /** 
     * 見積契約済承認した後、在庫を作成する。
     */ 
    public static void createInvProducts(Estimate__c estimate) {
        String soql = 'SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('OpportunityProduct__c'), ',');
        soql += ' FROM OpportunityProduct__c WHERE Estimates__c = \'' + estimate.Id + '\'  AND ProductType__c = \'仕入品\' AND ProductFlag__c = true';
        system.debug('soql:**'+soql); 
        
        //見積下、商品リスト
    	List<OpportunityProduct__c> oppProducts = Database.query(soql);
    	//商品Map
    	Map<Id, OpportunityProduct__c> oppProductMap = new Map<Id, OpportunityProduct__c>(oppProducts);
    	
    	//在庫を作成。
    	OpportunityProductTriggerHandler.createProducts(oppProducts,estimate,oppProductMap);
    }
    
    /** 
     * 御見積書を作成するバッチ(AUTO)
     * id id
     * linkedId リンクされているオブジェクトID
     * 仕組み：バッチ処理
     */
    @future (callout=true)
    public static void createMitumoriPDFBatch(String id ,String linkedId){                
        createMitumoriPdf(id,linkedId);
    }
    
     /** 
     * 支払予定表作成(AUTO)
     * linkedId 紐づけオブジェクトID
     * pdfType PDF種類
     * aggrementId 更新ID
     * 仕組み：バッチ処理
     */
    @future (callout=true)
    public static void createShiharaiPDFBatch(Id aggrementId, ID linkedId , String pdfType,String language) {
        createShiharaiPDF(aggrementId,linkedId,pdfType,language);
    }
    
    /** 
     * 請求書且契約作成(AUTO)
     * sObjId 見積ID
     * aggrementId 更新ID
     * 仕組み：バッチ処理
     */
    @future (callout=true)
    public static void saveKeiyakuAndInvoicePDF(Id sObjId, Id aggrementId , String recordTypeName) {
    	Estimate__c ec = [SELECT MonthlyPrintFlag__c,EstimateLanguage__c,RecordType.Name 
	                     FROM Estimate__c
	                     WHERE id=: sObjId
	                     ];
    	//契約書
    	if (recordTypeName != '販売') {
    		if(ec.EstimateLanguage__c=='英語'){
    			savePDFENGCommon(aggrementId, 'Contract' ,sObjId);
    		}else{
    			savePDFCommon(aggrementId, 'Contract' ,sObjId);
    		}
    	}
    	if(ec.MonthlyPrintFlag__c){
	        createInvoicePDF('Estimate__c' , sObjId , ec.EstimateLanguage__c);
    	}
    }
    
    /** 
     * 保証金返金とダメージ料金
     * sObjId 更新ID
     * 仕組み：バッチ処理
     */
    @future (callout=true)
    public static void saveHosyokinAndDamage(Id sObjId , Boolean HosyokinFlg , Boolean DamageFlg) {
		 Agreement__c ag = [SELECT Estimate__r.EstimateLanguage__c,Estimate__r.RecordType.Name 
	                     FROM Agreement__c
	                     WHERE id=: sObjId
	                     ];
    	if (HosyokinFlg) {
             if(ag.Estimate__r.EstimateLanguage__c=='英語'){
                //保証金返金
	            savePDFENGCommon(sObjId, 'Hosyokin' ,sObjId);
            }else{
	            //保証金返金
	            savePDFCommon(sObjId, 'Hosyokin' ,sObjId);
            }
    	}
    	//保証金返金の場合、販売モデンの請求を作成する。
    	if (DamageFlg) {
	        PageReference pageRef= null;
	        pageRef= Page.InvoiceHosyoukinPDF;
	        pageRef.getParameters().put('id', sObjId );
	        createPdfFile(pageRef, CommonUntil.Invoice ,sObjId);
    	}
    }
    
    /** 
     * 契約IDより、契約を取得する。
     * Id 契約ID
     */
    @AuraEnabled
    public static Agreement__c getAgreementById (Id id) {
        Agreement__c agreement = [SELECT Id,PaymentCount__c,LeaseAllTotal__c,
                                       shokaileasefee__c,SyokaiLeaseTax__c,MonthlyLeaseFeeTotal2__c,
                                       FirstPaymentDate__c,
                                       Estimate__r.Opportunity__r.Account.PaymentMethod__c,     //支払方法
                                       Estimate__r.Opportunity__r.Account.Card_date__c,         //カード期日
                                       Estimate__r.Opportunity__r.Account.Transfer_date__c,     //振込期日
                                       Estimate__r.FirstKikanTo1__c,
                                       Estimate__r.LeaseTerm__r.ContractEndSellingRate__c,
                                       Estimate__r.LeaseTerm__r.PostRenewalRate1__c,
                                       Estimate__r.LeaseTerm__r.PostRenewalRate2__c,
                                       Estimate__r.Seikyusaki__c,                //請求先
                                       Estimate__r.Opportunity__r.UserNew__c,    //使用者
                                       Estimate__r.RecordType.Name,
                                       NextLeaseStart__c,          //（次）リース開始日
                                       NextLeaseEnd__c,            //（次）リース終了日
                                       LeaseStart__c,              //リース開始日
                                       Estimate__c,                //見積
                                       KaiyakuDate__c,             //解約日
                                       NyukinKiaknStartDate__c,    //入金期間開始日
                                       ZanzonStartDate__c,         //残存ﾘｰｽ期間開始日
                                       ZanzonEndDate__c,           //残存ﾘｰｽ期間終了日
                                       NyukinKiaknEndDate__c,      //入金期間終了日
                                       NyukinOverAmount__c,        //入金済金額
                                       ZanzonLeaseAmount__c,       //残存リース料
                                       ParentAgreement__c,         //元更新
                                       ExpirationOrCancell__c,     //満了-途中解約
                                       TotalAcceptanceUponContract__c,
                                       HosyokinPDFFlag__c,         //保証金返金PDF
                                       SeikyuPDF__c,               //請求書(販売)PDF
                                       ApprovalStatus__c,          //承認状況
                                       ProductKaitoriCnt__c,       //買取商品件数(集計)
                                       TotalFee__c,                //(保証金返金)差引
                                       LeaseTermEndFlg__c,         //リース期間満了印刷済フラグ
                                       PaymentAmountSum__c,
                                       MonthlyLeaseFeeTax__c,
                                       PaymentAmountWithTaxSum__c,
                                       Estimate__r.PayAmountWithTax__c,
                                       Status__c,                  //ステータス
                                       SyokaiLeaseMonthCnt__c,     //初回リース月数
                                       UpdateCnt__c,               //更新回数
                                       (SELECT Id,Name,ProductFlag__c FROM InventoryOpportunityProduct__r),
                                       (SELECT Name,KijitsuDate__c,Payment__c FROM rel_PaymentDetails__r)
                                FROM Agreement__c
                                WHERE id=: id];
        return agreement;
    }
}