@isTest
public class TestDataFactory {
    //設置場所マスタ
    static List<InstallationLocation__c> ils;
    public static List<InstallationLocation__c> getInstallationLocation(){
        return ils;
    }   
    
    //リース料率マスタ LeaseRateMaster__c
    static  List<LeaseRateMaster__c> lrms;
    public static List<LeaseRateMaster__c> getLeaseRateMaster(){
        return lrms;
    }   
    
    //仕入先
    static  Account shireAccount;
    public static Account getShireAccount(){
        return shireAccount;
    }           
    
    //メーカーマスタ
    static  List<Maker__c> mks;
    public static List<Maker__c> getMaker(){
        return mks;
    }           
    
    //商品カテゴリマスタ
    static  List<CustomObjectProductCategory__c> pcs;
    public static List<CustomObjectProductCategory__c> getProductCategory(){
        return pcs;
    }           
    
    //商品マスタ
    static  List<CustomObjectProductMaster__c> pms;
    public static List<CustomObjectProductMaster__c> getProductMaster(){
        return pms;
    }   

    //仕入別メーカー別マスタ
    static List<PurchaseProductMaster__c> ppms;
    public static List<PurchaseProductMaster__c> getPurchaseProductMaster(){
        return ppms;
    }
    
    //在庫 
    static List<InventoryProduct__c> ips;
    public static List<InventoryProduct__c> getInventoryProduct(){
        return ips;
    }

    //法人販売先
    static List<Account> salesHojinAccts;
    public static List<Account> getsalesHojinAccount(){
        return salesHojinAccts;
    }    
    
    //商談
    static List<Opportunity> opps;
    public static List<Opportunity> getOpportunity(){
        return opps;
    }   
             
    //リース見積
    static List<Estimate__c> leaseEstimates;
    public static List<Estimate__c> getLeaseEstimate(){
        return leaseEstimates;
    }
    
    //リース見積に紐づけ契約
    static List<Agreement__c> agreements;
    public static List<Agreement__c> getAgreements(){
        return agreements;
    }
    
    //リース見積に紐づけ配送
    static List<Delivery__c> deliverys;
    public static List<Delivery__c> getDeliverys(){
        return deliverys;
    }
    
    //リース見積に紐づけ仕入
    static List<Purchase__c> purchases;
    public static List<Purchase__c> getPurchases(){
        return purchases;
    }
    
    //商品
    static List<OpportunityProduct__c> oppProducts;
    public static List<OpportunityProduct__c> getOppProducts(){
        return oppProducts;
    }
    
    //支払予定明細
    static List<PaymentDetails__c> paymentDetails;
    public static List<PaymentDetails__c> getPaymentDetails(){
        return paymentDetails;
    }
    
    //請求
    static List<Billed__c> billeds;
    public static List<Billed__c> getBilleds(){
        return billeds;
    }
    
    //請求明細
    static List<BilledDetail__c> billedDetails;
    public static List<BilledDetail__c> getBilledDetails(){
        return billedDetails;
    }
    
    //在庫案件商品
    static List<InventoryOpportunityProduct__c> invOppProducts;
    public static List<InventoryOpportunityProduct__c> getInvOppProducts(){
        return invOppProducts;
    }           
    
    public static void createAllMstData() {
        //設置場所マスタ
        ils = createInstallationLocation();
        
        //リース料率マスタ LeaseRateMaster__c
        lrms = createLeaseRateMaster();

        //仕入先
        shireAccount = createShireAccount();
        
        //メーカーマスタ
        mks = createMaker();
        
        //商品カテゴリマスタ
        pcs = createProductCategory();
        
        //商品マスタ
        pms = new List<CustomObjectProductMaster__c>();
        for (Integer i=0;i<pcs.size();i++) {
            for (Integer j=0;j<ils.size();j++) {
                CustomObjectProductMaster__c pm = createProductMaster( (i + 1) * (j + 1), pcs[i], ils[j], shireAccount, mks[0]);
                pms.add(pm);
            }
        }

        //仕入別メーカー別マスタ
        ppms = createPurchaseProductMaster(shireAccount, mks[0], pms[0]);
        
        //在庫 
        ips = new List<InventoryProduct__c>();
        for (Integer i=0;i<pms.size();i++) {
            for (Integer j=0;j<ils.size();j++) {
                InventoryProduct__c ip = createInventoryProduct( pms[0]);
                ips.add(ip);
            }
        }
        
        //法人販売先＆商談
        salesHojinAccts = createAccounts(1, '得意先');
        
        //商談
        opps = createOpportunitys(salesHojinAccts);
        
        //見積 リース
        leaseEstimates = createEstimate(opps, 'リース', lrms[0],salesHojinAccts);
        
        //リース見積に紐づけ契約
        agreements = createAgreements(leaseEstimates, opps);
        
        //リース見積に紐づけ配送
        deliverys = createDeliverys(leaseEstimates,agreements);
        
        //リース見積に紐づけ仕入
        purchases = createPurchases(leaseEstimates);
        
        //商品 リース
        oppProducts = createOppProducts(leaseEstimates,agreements,pms);
        
        //支払予定明細
        paymentDetails=createPaymentDetails(leaseEstimates,agreements);
        
        //在庫案件商品 リース
        invOppProducts = createInvOppProducts(oppProducts,ips[0],agreements);
        
        //請求
        billeds=createBilleds(salesHojinAccts,agreements);
        
        //請求明細
        billedDetails=createBilledDetails(billeds,agreements);
        
    }
    
    //設置場所マスタ
    public static List<InstallationLocation__c> createInstallationLocation() {
        List<InstallationLocation__c> ils = new List<InstallationLocation__c>();
        
        InstallationLocation__c il1 = new InstallationLocation__c(Name='ロビー', 
                                                        EnglishName__c= 'Lobby', //英語名
                                                        Number__c= 1 //番号
                                                    );
        ils.add(il1);
        
        InstallationLocation__c il2 = new InstallationLocation__c(Name='玄関', 
                                                        EnglishName__c= 'Entrance', //英語名
                                                        Number__c= 2 //番号
                                                    );
        ils.add(il2);

        insert ils;
        return ils;
    }
    
    //リース料率マスタ LeaseRateMaster__c
    public static List<LeaseRateMaster__c> createLeaseRateMaster() {
        List<LeaseRateMaster__c> lrms = new List<LeaseRateMaster__c>();
        
        //モデルルーム リース  長期  
        LeaseRateMaster__c l1 = new LeaseRateMaster__c(Name='モデルルームリース 36ヶ月', 
                                                        KeiyakuKikan__c= 36, //契約期間（ヶ月） 数値
                                                        InitialRate__c= 0.03, //月額リース料率 パーセント
                                                        PostRenewalRate1__c= 0.015,//更新後1料率 パーセント
                                                        PostRenewalRate2__c= 0.005,//更新後2料率 パーセント
                                                        Lease_ModelRoom__c= 'モデルルームリース',//通常/モデルルーム 選択リスト 通常リース モデルルームリース
                                                        ContractEndSellingRate__c= 0.03,//契約終了後の販売率 パーセント
                                                        SyokaiLeaseMonthCnt__c= 3,//初回リース月数 数値
                                                        Hosyokin__c= 3 //保証金月数 数値
                                                    );
        lrms.add(l1);
        
        //モデルルーム リース  短期
        LeaseRateMaster__c l2 = new LeaseRateMaster__c(Name='モデルルームリース 1ヶ月', 
                                                        KeiyakuKikan__c= 1, //契約期間（ヶ月） 数値
                                                        InitialRate__c= 0.4, //月額リース料率 パーセント
                                                        PostRenewalRate1__c= 0.05,//更新後1料率 パーセント
                                                        Lease_ModelRoom__c= 'モデルルームリース',//通常/モデルルーム 選択リスト 通常リース モデルルームリース
                                                        ContractEndSellingRate__c= 0.6,//契約終了後の販売率 パーセント
                                                        SyokaiLeaseMonthCnt__c= 1,//初回リース月数 数値
                                                        Hosyokin__c= 1 //保証金月数 数値
                                                    );
        lrms.add(l2);
        
        //通常 リース  長期
        LeaseRateMaster__c l3 = new LeaseRateMaster__c(Name='通常リース 12ヶ月', 
                                                        KeiyakuKikan__c= 12, //契約期間（ヶ月） 数値
                                                        InitialRate__c= 0.06, //月額リース料率 パーセント
                                                        PostRenewalRate1__c= 0.03,//更新後1料率 パーセント
                                                        PostRenewalRate2__c= 0.015,//更新後2料率 パーセント
                                                        Lease_ModelRoom__c= '通常リース',//通常/モデルルーム 選択リスト 通常リース モデルルームリース
                                                        ContractEndSellingRate__c= 0.3,//契約終了後の販売率 パーセント
                                                        SyokaiLeaseMonthCnt__c= 3,//初回リース月数 数値
                                                        Hosyokin__c= 3 //保証金月数 数値
                                                    );
        lrms.add(l3);
        
        //通常 リース  短期
        LeaseRateMaster__c l4 = new LeaseRateMaster__c(Name='通常リース 3ヶ月', 
                                                        KeiyakuKikan__c= 3, //契約期間（ヶ月） 数値
                                                        InitialRate__c= 0.1, //月額リース料率 パーセント
                                                        PostRenewalRate1__c= 0.1,//更新後1料率 パーセント
                                                        Lease_ModelRoom__c= '通常リース',//通常/モデルルーム 選択リスト 通常リース モデルルームリース
                                                        SyokaiLeaseMonthCnt__c= 3,//初回リース月数 数値
                                                        Hosyokin__c= 3 //保証金月数 数値
                                                    );
        lrms.add(l4);        

        insert lrms;
        return lrms;
    }

    //仕入先
    public static Account createShireAccount() {
        Account a = new Account(Name='仕入先',
                        RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('仕入先').getRecordTypeId()
                    );
        insert a;
        return a;
    }

    //メーカーマスタ
    public static List<Maker__c> createMaker() {
        List<Maker__c> mks = new List<Maker__c>();
        
        //大分類, 中分類
        Maker__c mk = new Maker__c(Name='アルテミデ', 
                                    EnglishName__c= 'ARTEMIDE', //英語名
                                    Number__c= '1', //番号
                                    OldNo__c= 'A0', //旧番号
                                    MakerLoadCost__c= false //メーカー搬入費有り
                                );
        mks.add(mk);        

        insert mks;
        return mks;
        
    }
    
    //仕入別メーカー別マスタ
    public static List<PurchaseProductMaster__c> createPurchaseProductMaster(Account shireAccount, Maker__c mk, CustomObjectProductMaster__c pm) {
        List<PurchaseProductMaster__c> ppms = new List<PurchaseProductMaster__c>();
        
        PurchaseProductMaster__c ppm1 = new PurchaseProductMaster__c(
                        Maker__c = mk.id, //メーカー
                        Vendor__c = shireAccount.id, //仕入先
                        PurchaseRate__c = 0.75, //仕入率
                        SellingRate__c = 0.8 //販売率
                    );
        ppms.add(ppm1);
                    
        PurchaseProductMaster__c ppm2 = new PurchaseProductMaster__c(
            Maker__c = mk.id, //メーカー
            Vendor__c = shireAccount.id, //仕入先
            ProductMaster__c = pm.id, //商品マスタ
            PurchaseRate__c = 0.7, //仕入率
            SellingRate__c = 0.78 //販売率
        );
        ppms.add(ppm2);
        
        insert ppms;
        return ppms;
    }
        
    //商品カテゴリマスタ
    public static List<CustomObjectProductCategory__c> createProductCategory() {
        List<CustomObjectProductCategory__c> pcs = new List<CustomObjectProductCategory__c>();
        
        //大分類, 中分類
        CustomObjectProductCategory__c pc1 = new CustomObjectProductCategory__c(Name='101', 
                                                        NotNeedHold__c= false, //HOLD不要
                                                        PackageProductFlag__c= false, //Package商品Flag
                                                        BigType__c= 'ソファ',//大分類
                                                        MediumType__c= '２Ｐソファ' //中分類
                                                    );
        pcs.add(pc1);

        //大分類, 中分類
        CustomObjectProductCategory__c pc2 = new CustomObjectProductCategory__c(Name='102', 
                                                        NotNeedHold__c= false, //HOLD不要
                                                        PackageProductFlag__c= false, //Package商品Flag
                                                        BigType__c= 'ソファ',//大分類
                                                        MediumType__c= '１Ｐソファ/イージーチェア' //中分類
                                                    );
        pcs.add(pc2);

        //大分類, 中分類, 小分類 1
        CustomObjectProductCategory__c pc3 = new CustomObjectProductCategory__c(Name='1201', 
                                                        NotNeedHold__c= false, //HOLD不要
                                                        PackageProductFlag__c= false, //Package商品Flag
                                                        BigType__c= '食器',//大分類
                                                        MediumType__c= '食器セット', //中分類
                                                        SmallType__c= '食器セットＮ2'//小分類
                                                    );
        pcs.add(pc3);

        //大分類, 中分類, 小分類 2
        CustomObjectProductCategory__c pc4 = new CustomObjectProductCategory__c(Name='1202', 
                                                        NotNeedHold__c= false, //HOLD不要
                                                        PackageProductFlag__c= false, //Package商品Flag
                                                        BigType__c= '食器',//大分類
                                                        MediumType__c= '食器セット', //中分類
                                                        SmallType__c= '食器セットU2'//小分類
                                                    );
        pcs.add(pc4);
        
        insert pcs;
        return pcs;
    }
    
    
    //商品マスタ
    public static CustomObjectProductMaster__c createProductMaster(Integer i, CustomObjectProductCategory__c pc, 
                    InstallationLocation__c il, Account ms, Maker__c mk) {

        CustomObjectProductMaster__c pm = new CustomObjectProductMaster__c(
                                                            //ProductName__c= 'ソファ' + i , //商品名
                                                            ProductNameEnglish__c= 'Long Sofa' + i, //商品名英語
                                                            ListPrice__c= 500 * i, //定価
                                                            ProductCategory__c= pc.id, //商品カテゴリ
                                                            InstallationLocation__c= il.id, //設置場所
                                                            MainSupplier__c= ms.id, //メイン仕入先
                                                            Maker__c= mk.id, //メーカー
                                                            ModelNumber__c= '型番_' + i, //型番
                                                            Accessories__c= 'PILLOW_' + i, //付属品
                                                            //SetupFeeFlag__c= false, //設置費用フラグ
                                                            Width__c= i, //幅（mm）
                                                            Depth__c= i,//奥行（mm）
                                                            Height__c= i, //高さ（mm）
                                                            Diameter__c= i, //  直径（mm）
                                                            Volume__c= i, //    体積（㎥）
                                                            Specification1__c= '仕様1_' + i, //仕様１
                                                            Specification2__c= '仕様2_' + i, //仕様2
                                                            Specification3__c= '仕様3_' + i, //仕様3
                                                            Specification4__c= '仕様4_' + i, //仕様4
                                                            Specification5__c= '仕様5_' + i, //仕様5
                                                            Specification6__c= '仕様5_' + i, //仕様6
                                                            Specification7__c= '仕様5_' + i, //仕様7
                                                            Specification8__c= '仕様6_' + i //仕様8
                                                            //Color__c= '白' //色
                                                            //Material__c= '素材_' + i //   素材
                                                        );
        
        insert pm;
        return pm;
    }
        
    //在庫 
    public static InventoryProduct__c createInventoryProduct(CustomObjectProductMaster__c pm) {
        InventoryProduct__c ip = new InventoryProduct__c(
                                                            HOLD__c = false, //HOLD
                                                            Rank__c = 'A', //ランク
                                                            CurrentStatus__c = '在庫', //現状区分
                                                            CurrentStatusAuxiliary__c = 'メンテ済', //現状補助区分
                                                            ProductMaster__c = pm.id, //商品マスタ
                                                            ProductPrice__c = pm.ListPrice__c, //商品定価
                                                            InstallationLocation__c = pm.InstallationLocation__c, //設置場所
                                                            SoukoOrSR__c = '倉庫', //倉庫/SR
                                                            LongOrShort__c = '長期専用', //長期専用/短期専用
                                                            ModelNumber__c= pm.ModelNumber__c, //型番
                                                            Accessories__c= pm.Accessories__c, //付属品
                                                            Width__c= pm.Width__c, //幅（mm）
                                                            Depth__c= pm.Depth__c,//奥行（mm）
                                                            Height__c= pm.Height__c, //高さ（mm）
                                                            Diameter__c= pm.Diameter__c, // 直径（mm）
                                                            Volume__c= pm.Volume__c, // 体積（㎥）
                                                            Specification1__c= pm.Specification1__c, //仕様１
                                                            Specification2__c= pm.Specification2__c, //仕様2
                                                            Specification3__c= pm.Specification3__c, //仕様3
                                                            Specification4__c= pm.Specification4__c, //仕様4
                                                            Specification5__c= pm.Specification5__c, //仕様5
                                                            Specification6__c= pm.Specification6__c, //仕様6
                                                            Specification7__c= pm.Specification7__c, //仕様7
                                                            Specification8__c= pm.Specification8__c //仕様8
                                                            //Color__c= pm.Color__c //色                                                          
                                                            //Material__c= pm.Material__c //  素材  
                                                            );
        
        insert ip;
        return ip;
    }


    //取引先
    public static List<Account> createAccounts(Integer numAccts, String recordTypeName) {
    	Account ac= new Account(Name='メイズ',SelfCmpFlag__c=true);
    	insert ac;
        List<Account> accts = new List<Account>();
        
        for(Integer i=0;i<numAccts;i++) {
            Account a = new Account(Name='TestAccount' + i,
                                    RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId());
            accts.add(a);
        }
        insert accts;
        return accts;
    }
    
    //商談
    public static List<Opportunity> createOpportunitys(List<Account> accts) {
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer j=0;j<accts.size();j++) {
            Account acct = accts[j];
            opps.add(new Opportunity(Name=acct.Name + ' Opportunity ' + j,
                                   StageName='見積・提案',
                                   CloseDate=System.today().addMonths(1),
                                   AccountId=acct.Id));
        }

        insert opps;       
        return opps;
    }
    
    //見積
    public static List<Estimate__c> createEstimate(List<Opportunity> opps, String recordTypeName, LeaseRateMaster__c lt,List<Account> accts) {
        List<Estimate__c> estimates = new List<Estimate__c>();
        for (Integer j=0;j<opps.size();j++) {
            Opportunity opp = opps[j];
            estimates.add(new Estimate__c(
                                   RecordtypeId = Schema.SObjectType.Estimate__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId(),
                                   Opportunity__c = opp.id, //案件
                                   LeaseTerm__c=lt.id, //リース契約期間
                                   QuotationStatus__c = '見積', //見積ステータス
                                   QuotationType__c = '御見積書（基本契約）', //見積タイプ
                                   EstimatedDate__c=System.today(), //見積日
                                   LeaseStart__c=System.today(),//LeaseStart__c
                                   LeaseEnd__c=System.today().addMonths(12),//LeaseStart__c
                                   SyokaiLeaseMonthCnt__c=3,//初回ﾘｰｽ月数（ヶ月）
               					   MonthlyLeaseRate__c= lt.InitialRate__c,//月額リース料率
               					   Seikyusaki__c=accts[j].Id,//請求先
               					   ApprovalStatus__c = '未提出'
                                   ));
        }
        insert estimates;       
        return estimates;
    }
 
    //リース見積に紐づけ配送
    public static List<Delivery__c>  createDeliverys(List<Estimate__c> estimates , List<Agreement__c> agreements) {
        List<Delivery__c> deliverys = new List<Delivery__c>();
        for (Integer j=0;j<estimates.size();j++) {
            Estimate__c estimate = estimates[j];
            Agreement__c agreement = agreements[j];
            deliverys.add(new Delivery__c(
                                   Estimate__c = estimate.Id,
                                   Agreement__c = agreement.Id,
                                   DeliveryDate__c = Date.today()
                                   ));
        }
        insert deliverys;       
        return deliverys;
    }
    
    //リース見積に紐づけ契約
    public static List<Agreement__c>  createAgreements(List<Estimate__c> estimates,List<Opportunity> opps) {
        List<Agreement__c> newAgreements = new List<Agreement__c>();
        for (Integer j=0;j<estimates.size();j++) {
            newAgreements.add(new Agreement__c(
                                   Estimate__c = estimates[j].Id,
                                   //Oppotunity__c = opps[j].Id,
                                   LeaseStart__c=Date.today(),
                                   Name = 'L0000_000',
                                   LeaseEnd__c=Date.today().addMonths(3)
                                   ));
        }
        insert newAgreements;       
        return newAgreements;
    }
    
    //リース見積に紐づけ仕入
    public static List<Purchase__c>  createPurchases(List<Estimate__c> estimates) {
        List<Purchase__c> purchases = new List<Purchase__c>();
        for (Integer j=0;j<estimates.size();j++) {
            Estimate__c estimate = estimates[j];
            purchases.add(new Purchase__c(
                                   Estimate__c = estimate.Id
                                   ));
        }
        insert purchases;       
        return purchases;
    }
    
    //商品
    public static List<OpportunityProduct__c>  createOppProducts(List<Estimate__c> estimates ,List<Agreement__c> agreements,List<CustomObjectProductMaster__c> pms) {
        List<OpportunityProduct__c> oppProducts = new List<OpportunityProduct__c>();
        for (Integer j=0;j<estimates.size();j++) {
            Estimate__c estimate = estimates[j];
            oppProducts.add(new OpportunityProduct__c(
                                   Estimates__c = estimates[j].Id,
                                   Contract__c = agreements[j].Id,
                                   Product__c=pms[j].Id
                                   ));
        }
        system.debug(oppProducts);
        insert oppProducts;       
        return oppProducts;
        
    }
    //支払予定明細
    public static List<PaymentDetails__c>  createPaymentDetails(List<Estimate__c> estimates ,List<Agreement__c> agreements) {
        List<PaymentDetails__c> paymentDetails = new List<PaymentDetails__c>();
        for (Integer j=0;j<estimates.size();j++) {
            Estimate__c estimate = estimates[j];
            paymentDetails.add(new PaymentDetails__c(
                                   Estimate__c = estimates[j].Id,
                                   Agreement__c = agreements[j].Id,
                                   KijitsuDate__c=Date.today(),
                                   Count__c = 1
                                   ));
        }
        insert paymentDetails;       
        return paymentDetails;
    }
    //請求
    public static List<Billed__c>  createBilleds(List<Account> accts,List<Agreement__c> agreements) {
        List<Billed__c> billeds = new List<Billed__c>();
        for (Integer j=0;j<accts.size();j++) {
            Account acc = accts[j];
            billeds.add(new Billed__c(
                                  Account__c=acc.Id,
                                  Type__c = 'リース',
                                  agrement__c=agreements[j].Id
                                   ));
        }
        insert billeds;       
        return billeds;
    }
    //請求明細
    public static List<BilledDetail__c>  createBilledDetails(List<Billed__c> billeds,List<Agreement__c> agreements) {
        List<BilledDetail__c> billedDetails= new List<BilledDetail__c>();
        for (Integer j=0;j<billeds.size();j++) {
            Billed__c billed = billeds[j];
            billedDetails.add(new BilledDetail__c(
                                  Billed__c=billed.Id,
                                  Count__c = 1,
                                  Agreement__c=agreements[j].Id,
                                  TotalLeaseAmount2__c=10000
                                   ));
        }
        insert billedDetails;       
        return billedDetails;
    }
    //在庫案件商品
    public static List<InventoryOpportunityProduct__c>  createInvOppProducts(List<OpportunityProduct__c> oppProducts,InventoryProduct__c zaiko,List<Agreement__c> agreements) {
        List<InventoryOpportunityProduct__c> invOppProducts = new List<InventoryOpportunityProduct__c>();
        for (Integer j=0;j<oppProducts.size();j++) {
            OpportunityProduct__c oppProduct = oppProducts[j];
            invOppProducts.add(new InventoryOpportunityProduct__c(
                                   OpportunityProduct__c = oppProduct.Id,
                                   InventoryProduct__c = zaiko.Id,
                                   Agreement__c=agreements[j].Id
                                   ));
        }
        insert invOppProducts;       
        return invOppProducts;
    }
    
}