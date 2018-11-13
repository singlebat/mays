public class ShiharaiPDFController {
	
    //支払予定明細  
    public List<PaymentDetails__c> shiharaisA  {get;set;}
    public List<PaymentDetails__c> shiharaisB  {get;set;}
    
    //契約id
    public String  agreementId {get;set;}
    
    //更新
    public Agreement__c agreement {get;set;}
    
    /*コンスタント*/
    public  ShiharaiPDFController(){
        agreementId=ApexPages.currentPage().getParameters().get('id');
        System.debug('agreementId:' + agreementId);
        //Test
        //agreementId = 'a0A0k00000701NT';
        getAgreement(agreementId);
        getShiharaiData();
    }

    public void getAgreement(String  agreementId){

        agreement = [SELECT 
                          ContractorPostalCode__c,          //契約先(郵便番号)
                          ContractorAdress__c,              //契約先(住所)
                          ContractorAdress_En__c,			//契約先(住所)英語
                          Contractors__c,                   //契約先
                          Name,                             //お問合せNo.
                          TeiketuDay__c,                    //締結日
                          LeaseStart__c,                    //リース開始日
                          LeaseEnd__c,                      //リース終了日
                          PaymentCount__c,                  //お支払回数
                          PaymentMethod__c,                 //お支払方法
                          PaymentAmountSum__c,              //お契約総額
                          PaymentAmountWithTaxSum__c,       //お契約総額(保証金消費税含み)
                          Estimate__r.PayAmountWithTax__c,  //お支払総額(保証金消費税含み)
                          MonthlyLeaseFeeTotal2__c,         //月額リース料（集計）
                          MonthlyLeaseFeeTax__c,            //月額リース料消費税
                          UserNew__c,                       //使用者
                          UpdateCnt__c,                     //更新回数
                          PropertyAddress__c,               //場所（物件名）住所
                          PropertyHomeNo__c,                //物件名・部屋番号                                                                             
                                (SELECT 
                                        Count__c,               //回数
                                        KijitsuDate__c,         //支払期日
                                        BilledKikanStart__c,    //請求対象期間(開始)(リ)
                                        ReturnBilledKikanEnd__c,//請求対象期間(終了)(リ)
                                        Payment__c,             //支払金額
                                        PaymentBalance__c       //支払残高                                                                                                                        
                                     FROM rel_PaymentDetails__r ORDER BY  Count__c)
                        FROM Agreement__c
                        WHERE id=:agreementId
                             
                      ];
           System.debug('agreement:' + agreement);

    }

    /**
     * 支払予定表取得,左と右の二つの部分にする
     */
    public void getShiharaiData(){
        this.shiharaisA=new List<PaymentDetails__c>();
        this.shiharaisB=new List<PaymentDetails__c>();
        List<PaymentDetails__c> shiharais=agreement.rel_PaymentDetails__r;
        Integer n=shiharais.size();
        for(Integer i=1;i<=40-n;i++){  
                 PaymentDetails__c c=new PaymentDetails__c(); 
                 shiharais.add(c);
        }
        system.debug(shiharais.size());
        for(Integer i=0;i<=39;i++){
            if(i<=19){
                shiharaisA.add(shiharais[i]);
                system.debug(shiharaisA.size());
            }else{
                system.debug(shiharaisA.size());
                shiharaisB.add(shiharais[i]);
            }
        }
    }
}