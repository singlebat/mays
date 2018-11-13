public with sharing class PurchasePdfController extends PagingPdfAbstractController{
    
    //ページ分ける
    //public List<pageTotal> pageTotalList{get;set;}
	public List<String> modelTotalList{get;set;}
	
    public List<OpportunityProduct__c>  product{get;set;}
    
    //仕入
    public Purchase__c purchase{get;set;}
    
    //納品の日付
    public String nodate{get;set;}
    
    //納品の時間
    public String notime{get;set;}
    
    //備考
    public String bikou{get;set;}
    
     //送料(下代)
    public Decimal shippingCost{get;set;}
    
    //「⾒積依頼書及び取置き依頼書」又は「注⽂書兼注⽂請書」
    public String pdfType{get;set;}
    
    /** 
     * コンスタント
     */
    public  PurchasePdfController(){
        //仕入ID
        String purchaseId = ApexPages.currentPage().getParameters().get('id');
        //納入日　時刻
        String deliveryTime2 = ApexPages.currentPage().getParameters().get('deliveryTime2');
        //「⾒積依頼書及び取置き依頼書」又は「注⽂書兼注⽂請書」
        pdfType = ApexPages.currentPage().getParameters().get('pdfType');
        //備考
        bikou = ApexPages.currentPage().getParameters().get('bikou');
		//送料(下代)
        String Cost = ApexPages.currentPage().getParameters().get('shippingCost');
     	if(Cost!='' && Cost!= null){
     		shippingCost=Decimal.valueOf(Cost);
     	}
        system.debug('purchaseId: '+purchaseId);
        system.debug('deliveryTime2: '+deliveryTime2);
        system.debug('pdfType: '+pdfType);
        system.debug('bikou: '+bikou);

         //Test
        //pdfType='Order';
        //pdfType='Mitsumoridepend'; 
        //purchaseId='a0K0k0000019HcCEAU';
        getPDFData(purchaseId,deliveryTime2);
        
    }
    
    /** 
     * 納期確認及び見積依頼書 / 注⽂書兼注⽂請書
     */
    public void getPDFData(String purchaseId , String deliveryTime2){
        modelTotalList = new List<String>();
        //仕入
        purchase = [SELECT 
                        Suppliers__r.Name,    //[仕入先].取引先名
                        Contact_name__c,      // 仕入先担当者
                        Fax__c,               //仕入先Fax
                        Estimate__r.Opportunity__r.Owner.Name,           //所有者
                        NonyusakiName__c,     //納入先氏名
                        PropertyAddress__c,   //場所（物件名）住所
                        PropertyHomeNo__c,    //物件名・部屋番号
                        UserTel__c,           //使用者電話
                        ShippingCost__c,      //送料(下代)
                        Estimate__r.TAX__c,  
                                 (SELECT 
                                          Maker__c,           //メーカー
                                          Name,               //商品名
                                          ModelTotal__c,      //型番 (自動)     
                                          Quantity__c,        //数量
                                          MakerPrice__c,      //標準小売価格(単価)
                                          ProductListPrice__c,//標準小売価格(合計)
                                          PurchaseRate__c,    //仕入率
                                          SalesCost__c,       //下代
                                          SalesCostSum__c,    //下代(合計)
                                          Specification__c,   //仕様
                                          ToriyokiFlag__c,    //取置き依頼
                                          Purchase__r.Estimate__r.TAX__c        
                                    FROM OpporProduct__r 
                                    WHERE Product__r.SetupFeeFlag__c = false )
             FROM Purchase__c WHERE ID =:purchaseId ];
        
        system.debug('purchase: '+purchase);
        
        //納品の日付と時刻を区分する
        if (deliveryTime2 != null) {
            nodate = DateTime.valueOf(deliveryTime2).format('yyyy年MM月dd日');
            notime = DateTime.valueOf(deliveryTime2).format('HH:mm');
        }
       
        //商品のlist、価格合計のため
         product=purchase.OpporProduct__r;
        
        //標準小売価格合計例の合計
        Decimal account=0;
        for (Integer i=0;i<product.size();i++){
            account=account+product[i].ProductListPrice__c;
        }
        Decimal accountTAX=account*purchase.Estimate__r.TAX__c*0.01;
        //標準小売価格合計例の合計
        for (Integer i= product.size();i< maxMeisaiSize;i++){
            OpportunityProduct__c Oppor =new OpportunityProduct__c();
            product.add(Oppor);
        }

        //pageTotalList=getPageTotalByList(product);
        
        for(OpportunityProduct__c p: purchase.OpporProduct__r){
        	String modelTotal = p.ModelTotal__c == null ? '' : p.ModelTotal__c;
        	if(modelTotal.length()>38){	
        		if(modelTotal.length()>38 && modelTotal.length()<64){
        			modelTotal= modelTotal.substring(0,38)+'<br/>'+modelTotal.substring(38) ;
        		}else if(modelTotal.length()>64){
        			modelTotal= modelTotal.substring(0,38)+'<br/>'+modelTotal.substring(38,64) +'<br/>'+modelTotal.substring(64);
        		}
        		modelTotal= '<div style=\'font-size:5px;\'>' + modelTotal+ '</div>';
        	}
        	modelTotalList.add(modelTotal);
        }
        system.debug(modelTotalList);
    }
    
}