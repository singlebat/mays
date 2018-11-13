public with sharing class MitumoriPdfController extends PagingPdfAbstractController{
    
    //見積
    public Estimate__c mitumori {get;set; }
    
    //見積id
    public String  mitumoruId {get;set;}
    
    //RemarksFormular__c
    public String  remarks{get;set;}
    
    //設置場所で分组用
    public List<productTotal> Listproduct {get;set;}
    
    //明細 flag判断のlist
    public List<OpportunityProduct__c> productmeisai {get;set;}
    
    //このプロセスを最後に承認、却下、または取り消したアクター。
    public String lastActorName {get;set;}
    
    //見積所有者
    public String createdUserName {get;set;}
    
    //型番非表示(見積表示条件)     
    public Boolean  modelNumberHide{get;set;}
    
    /** 
     * コンスタント
     */
    
    public  MitumoriPdfController(){
        mitumoruId=ApexPages.currentPage().getParameters().get('id');
       
        //test用
        //modelNumberHide=false;
        //リース
        //mitumoruId = 'a000k0000046aGjAAI';
        //販売
        //mitumoruId = 'a000k000004XwVDAA0';
        //system.debug('mitumoruId: '+mitumoruId);
        

        //PDFデータを取得
        getPDFData(mitumoruId,'');
        
        //商品明細をセット
        setOpportunityProduct();
        
        //費用明細をセット
        setProductmeisai();     
    
        //承認者 & remarksをセット  
        setLastActorNameAndRemarks();
    }
    
    /** 
     * PDFデータを取得
     */
    void getPDFData(String mitumoruId, String deliveryTime2){
        mitumori=[SELECT 
        			  RecordType.Name,
                      Name,                 //お問合せNo.
                      EstimatedDate__c,     //見積日
                      ExpirationDate__c,    //有効期限
                      SubTitle__c,          //サブタイトル                                  
                      Account__c,           //取引先 
                      Account_number__c,    // (非表示)お客様番号                                                                           
                      UserNewName__c,       //使用者名
                      PropertyAddress__c,   //場所（物件名）住所  
                      PropertyHomeNo__c,    //物件名・部屋番号
                      //TODO 承認者の電子印
                      CreatedById,          //TODO 見積所有者の電子印
                      LeaseStart__c,           //リース開始日
                      LeaseEnd__c,             //リース終了日
                      LeaseMonth__c,           //リース月数
                      MonthlyLeaseRate__c,     //月額リース料率
                      MonthlyLeaseFeeTotal__c, //月額リース料（集計） & 明細
                      MonthlyLeaseFeeTax__c,   //月額リース料消費税
                      LeaseAllTotal__c,        //リース料総額
                      LeaseAllTotalTax__c,     //リース料総額消費税
                      PaymentAmountSum__c,     // お支払総額(保証金含み)                 
                      PaymentAmountSumTax__c,  //お支払総額消費税
                      PaymentAmountWithTaxSum__c, //お支払総額(保証金消費税含み)
                      TotalAcceptanceUponContract__c,//契約時申受金合計
                      shokaileasefee__c,       //初回リース料金
                      FirstKikanTo1__c,        //初回リース料期間（TO）
                      SyokaiLeaseTax__c,       //初回リース料金消費税
                      CostTotalTax__c,         //諸費用総額消費税
                      Ken_SpecialDiscount__c  , //KEN様特別値引き
                      DiscountAmount__c,       //出精値引
                      DepositMonth__c,         //保証金月数（ヶ月） 
                      hoshokin__c,             //保証金
                      RemarksFormular__c,      //御見積条件等
                      AttentionMsg__c,         //(非表示)注意メッセージ        
                      AttentionMsgENG__c,      //(非表示)注意メッセージENG                                                                    
                      QuotationStatus__c,      //ステータス  （判断条件）
                      ModelNumberHide__c,      //型番非表示フラグ
                      
                      AmountLeaseSum__c,       //計算価値価格(集計)  　　明細の合計
                      ProductListPriceSum__c,  //標準小売価格(集計)  　明細の合計
                      Seikyusaki__r.Name,      //請求先名
                      SeikyusakiAddress__c,    //請求先住所
                      Opportunity__r.CloseDate,//納品日
                      
                                  (SELECT 
                                        InventoryProductNo__c,   //(非表示)在庫番号
                                        U_N__c,                  //(非表示)U/N
                                        Name,                    //商品名                                                                                                                                                                                   
                                        ModelTotal__c,           //型番 (自動)
                                        Size__c,                 //サイズ
                                        MakerPrice__c,           //標準小売価格(単価)
                                        Quantity__c,             //数量
                                        ProductListPrice__c,     //標準小売価格(合計)
                                        AmountPercentLease__c,   // 計算価値価格(合計)                                    
                                        MonthlyLeaseFee__c,      //月額リース料(合計)
                                        Maker__c,                //メーカー
                                        Specification__c,        //仕様
                                        UnitPriceSales__c,
                                        UnitPriceLease__c,       // 計算価値価格  PDF用
                                        InstallationLocationOther__c,  //その他設置場所                            
                                        InstallationLocation__r.Name, //設置場所 名
                                        SetupFeeFlag__c,             //if条件用 費用フラグflag
                                        KENSpecialDiscountFlag__c,  //if条件用 出精値引フラグ
                                        DiscountFlag__c             //if条件用  KEN様特別値引きフラグ                        
                                    FROM rel_chxq__r 
                                    ORDER BY LocationNo__c NULLS LAST, InstallationLocation__c NULLS LAST , SetupFeeFlag__c,SortNo__c NULLS LAST,CreatedDate)
                  FROM Estimate__c 
                  WHERE id=: mitumoruId 
                  ];
                  
        User createdUser = [select Name,Email  from user where id = :mitumori.CreatedById];
        createdUserName = createdUser.Email.substring(0,createdUser.Email.indexOf('@')).replaceAll('\\.','').replaceAll('\\-','');
        system.debug('createdUserName::' + createdUserName);
       
    }
    
    //商品明細
    private void setOpportunityProduct(){
      system.debug(mitumori.rel_chxq__r);
        Id oldInstallationLocationId = null;
        
        Listproduct=new List<productTotal>();
		productTotal pt = new productTotal();
		
        for (OpportunityProduct__c opp:mitumori.rel_chxq__r) {
          //設置場所にgroupのため　および　費用フラグflag, 出精値引フラグ, KEN様特別値引きフラグ のfalseの場合　
          if (!opp.SetupFeeFlag__c && !opp.KENSpecialDiscountFlag__c && !opp.DiscountFlag__c) {
              /*if (oldProductId == null || oldProductId != opp.Id) {
                  Listproduct.add(new productTotal());
                    Listproduct[Listproduct.size() -1].basiyoname = opp.InstallationLocation__r.Name;
              }
              Listproduct[Listproduct.size() -1].productList.add(opp);
              */
              System.debug('each: oldInstallationLocationId:[' + oldInstallationLocationId + '] opp.InstallationLocation__c:['+ opp.InstallationLocation__c + ']');
              if (oldInstallationLocationId == null || oldInstallationLocationId != opp.InstallationLocation__c) {
              	pt = new productTotal();
              	if(opp.InstallationLocation__c !=null && opp.InstallationLocation__r.Name.contains('その他')){
              		pt.basiyoname = opp.InstallationLocationOther__c;
              	}else{
              		pt.basiyoname = opp.InstallationLocation__r.Name;
              	}
                Listproduct.add(pt);
                oldInstallationLocationId = opp.InstallationLocation__c;
                System.debug('if oldInstallationLocationId:[' + oldInstallationLocationId + ']');
              }
              
              pt.productList.add(opp);
          } 
        }
        
        System.debug(Listproduct);
    }
    
    //費用明細
    private void setProductmeisai(){
        //費用フラグflagのtrueの場合
        productmeisai=new List<OpportunityProduct__c>();
        for (OpportunityProduct__c  opp :mitumori.rel_chxq__r){
            if(opp.SetupFeeFlag__c){
                productmeisai.add(opp);
            }
        }
        //sizeの10のlist、不足のは空いた対象を充填
        if(mitumori.RecordType.Name!='販売'){
	        for (Integer i = productmeisai.size() ; i < maxMeisaiSize ; i++) {
	            productmeisai.add(new OpportunityProduct__c());
	        }
        }
        system.debug(mitumori.RecordType.Name);
        system.debug(productmeisai);
    }   
     
    private void setLastActorNameAndRemarks(){

        //承認済みの場合、承認者を取得する。
        if (mitumori.QuotationStatus__c != '見積' && mitumori.QuotationStatus__c != '無効') {
            List<ProcessInstance> p = [SELECT 
                                          Id,
                                          CompletedDate, 
                                          LastActorId, 
                                          ProcessDefinitionId, 
                                          Status, 
                                          TargetObjectId
                                       FROM ProcessInstance
                                       WHERE TargetObjectId = :mitumoruId
                                       AND Status = 'Approved'
                                       ORDER by CompletedDate asc 
                                       LIMIT 1
                                      ];
            system.debug(p);
            if (p.size() > 0) {
                User u = [select Name,Email  from user where id = :p[0].LastActorId];
                lastActorName = u.Email.substring(0,u.Email.indexOf('@')).replaceAll('\\.','').replaceAll('\\-','');
                system.debug('lastActorName::' + lastActorName);
            }
        }
        
        //remarks= ToolsClass.getHtmlSpanStrByRate(mitumori.RemarksFormular__c,60,2,12);
        remarks= mitumori.RemarksFormular__c;
        system.debug('remarks: '+remarks);

    }
    
    
    /** 
     * 設置場所番号分组用カスタマイズオブジェクト
     */
    public class productTotal{
        //設置場所のName
        public String basiyoname{get;set;}
        
        //groupの商品のlist
        public List<OpportunityProduct__c> productList{get;set;}
        
        public productTotal(){
            productList=new List<OpportunityProduct__c>();
        }
    }
}