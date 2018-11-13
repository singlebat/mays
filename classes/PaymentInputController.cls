public class PaymentInputController {
     public class Rows {
        /**
         * 正常件数
         */
        @AuraEnabled
    	public  Integer rightRows {get; set;}
        
         /**
         * 失敗件数
         */
        @AuraEnabled
    	public  Integer errorRows {get; set;}
    	
    	@AuraEnabled
    	public List<Payment__c>  paymentList= new List<Payment__c>();
    	
    	 /**
         * エラーメッセージが保存した場所 payList(全体エラーメッセージ)     detailList（個別明細エラーメッセージ）
         */
    	@AuraEnabled
    	public List<String>  payList= new List<String>();
    	@AuraEnabled
    	public List<PaymentInputDetail__c>  detailList= new List<PaymentInputDetail__c>();
    }
    public List<string> fileNameList {get; set;}
    public List<string> contentList {get; set;}
    //口座番号
	private Static string kouza='5007402';
    //口座番号フラグ
    private Static Map<Integer, Boolean> kouzaMap=new Map<Integer, Boolean>();
    //データ区分フラグ
    private Static Map<Integer, Boolean> dataType8=new Map<Integer, Boolean>();
    //合計件数フラグ
	private Static Map<Integer, Boolean> summary=new Map<Integer, Boolean>();
    //合計金額フラグ
	private Static Map<Integer, Boolean> summaryMonney=new Map<Integer, Boolean>();
    //データ区分フラグ
    private Static Map<Integer, Boolean> dataType9=new Map<Integer, Boolean>();

    @AuraEnabled
    public static List<PaymentInput__c> getAllFilesList(String recordId) {
        List<PaymentInput__c> fileList = new List<PaymentInput__c>();
        for(PaymentInput__c a: [select Id, Name, lastModifiedDate__c,  Filename__c, ContentSize__c,InputFlg__c
            from PaymentInput__c where Id=:recordId ORDER BY LastModifiedDate DESC]){
            fileList.add(a);
        }
        return fileList;
    }

    @AuraEnabled
    public static List<List<string>> getAllReferenceList() {
        List<List<string>> allList=new List<List<string>>();
        List<string> referenceList = new List<string>();
        for(PaymentInputDetail__c a: [select Id, Name, referenceNo__c
            													from PaymentInputDetail__c]){
            referenceList.add(a.referenceNo__c);
        }
        allList.add(referenceList);
        return allList;
    }


    @AuraEnabled
    public static List<List<string>> getAllAccountList() {
        List<List<string>> allList=new List<List<string>>();
        List<string> addressList = new List<string>();
        List<string> IdList = new List<string>();
        for(Account a: [select Id, Name, Bank_account_Nominee__c,Financial_Name__c,Financial_branch__c
            													from Account]){
            IdList.add(a.Id);
            //addressList.add(a.Bank_account_Nominee__c+a.Financial_Name__c+a.Financial_branch__c);
            addressList.add(a.Bank_account_Nominee__c);
        }
        allList.add(IdList);
        allList.add(addressList);
        return allList;
    }

    @AuraEnabled
    public static Id saveAttachment( String fileName,String content ) {
        //入金取込
		PaymentInput__c paymentInput=new PaymentInput__c();
        //ファイル名
		paymentInput.Filename__c=fileName;
        //入金取込名

        //取込状態
        paymentInput.InputFlg__c=true;
        // ファイルにINSERT
        //
        insert paymentInput;

        return paymentInput.Id;
    }

    /**
     * バッチ小EXCLEの見積添付ファイルへ処理
     */
    @AuraEnabled
    public static Rows saveBatchFiles(String files) {
        system.debug('files:'+files);
		Rows Rrows= new Rows();
        //入金取込
		List<PaymentInput__c> paymentInputList = new List<PaymentInput__c>();
        //挿入用入金取込詳細
        List<PaymentInputDetail__c> paymentInputDetailInsert = new List<PaymentInputDetail__c>();
        //更新用入金取込詳細
        //List<PaymentInputDetail__c> paymentInputDetailUpdate = new List<PaymentInputDetail__c>();

        //一時リスト
        List<List<PaymentInputDetail__c>> TempList =new List<List<PaymentInputDetail__c>>();

        //一時リスト3
        List<List<string>> TempList3 =new List<List<string>>();
        //ファイルの中身をゲット
        List<PayFile> fileList = (List<PayFile>)System.JSON.deserializeStrict(files,List<PayFile>.Class);
        ///////////////////////////////①//////////////////////////////
        //入金取込を保存
        for(PayFile file: fileList){
            PaymentInput__c paymentInput=new PaymentInput__c();
            //ファイル名
            paymentInput.Filename__c=file.name;
            //取込状態
            paymentInput.InputFlg__c=true;
            //ファイルサイズ
            paymentInput.ContentSize__c=file.size;
            paymentInputList.add(paymentInput);
        }
        //入金取込を保存
        insert paymentInputList;
        ///////////////////////////////①//////////////////////////////
        ///////////////////////////////////②//////////////////////////////
        string[] arr;
        //入金取込ファイルのカウンター
        Integer ifile=0;
        //入金取込ファイルのレコード数
        Integer iRecord=0;
        for(PayFile file: fileList){
            //default値は【口座番号】が正しい
            kouzaMap.put(ifile,true);
            //default値はチェック失敗
            dataType8.put(ifile,false);
            summary.put(ifile,false);
            summaryMonney.put(ifile,false);
            dataType9.put(ifile,false);

            iRecord=0;

            List<PaymentInputDetail__c> detailtempList=new  List<PaymentInputDetail__c>();
            List<string> stringtempList=new  List<string>();
            //列ごとの配列をゲットする
            arr=file.content.split('\r\n');
            for(string arrNum:arr){
	                //その一列のデータ
					arrNum=arrNum.replace('.,', '***');
	            	string[] aNum=arrNum.split(',');

	                if(aNum[0]=='1'){
	                    if(aNum[11]!=kouza){
	                        kouzaMap.put(ifile,false);
	                        //メッセージ：　振込CSVファイルのヘッダー【口座番号】が間違い　
	                    }
	                }
	                //入金取込詳細
	                if(aNum[0]=='2'){
                        PaymentInputDetail__c paymentInputDetailTemp = new PaymentInputDetail__c();
                        paymentInputDetailTemp.Datatype__c=aNum[0];
						paymentInputDetailTemp.referenceNo__c=aNum[1];
                        paymentInputDetailTemp.PaymentDate__c=convertDate(aNum[2]);
                        paymentInputDetailTemp.startDate__c=convertDate(aNum[3]);
                        paymentInputDetailTemp.Payment__c=Decimal.ValueOF(aNum[4]);
                        paymentInputDetailTemp.Pocketpayment__c=Decimal.ValueOF(aNum[5]);
                        paymentInputDetailTemp.personCode__c=aNum[6];
                        paymentInputDetailTemp.Bank_account_Nominee__c=aNum[7];
                        paymentInputDetailTemp.Financial_Name__c=aNum[8];
                        paymentInputDetailTemp.Financial_branch__c=aNum[9];
                        paymentInputDetailTemp.cancelType__c=aNum[10].replace('***', '.,');
                        paymentInputDetailTemp.EDI__c=aNum[11];
                        paymentInputDetailTemp.dami__c=aNum[12];
                        paymentInputDetailTemp.rePayment__c=paymentInputList[ifile].Id;
                        detailtempList.add(paymentInputDetailTemp);
						stringtempList.add(aNum[1]);
                        iRecord=iRecord+1;
	                }
	                if(aNum[0]=='8'){
	                	//データ区分フラグ
	                    dataType8.put(ifile,true);
	                    if(aNum[1]!=null&&aNum[1]!=''){
	                    	//合計件数フラグ
	                    	summary.put(ifile,true);
	                    	if(aNum[2]!=null&&aNum[2]!=''){
	                    		//合計金額フラグ
								summaryMonney.put(ifile,true);
	                    	}
	                    }
	                }
	                if(aNum[0]=='9'){
	                	//データ区分フラグ
	                    dataType9.put(ifile,true);
	                }
        		}
            paymentInputList[ifile].recordAccount__c=iRecord;
            TempList.add(detailtempList);
            TempList3.add(stringtempList);
            ifile=ifile+1;
        }

		//チェック結果を返す
		system.debug('detailtempList'+TempList);
		system.debug('kouzaMap'+kouzaMap);
		checkFlg(kouzaMap,TempList,paymentInputList,'1');
       	checkFlg(dataType8,TempList,paymentInputList,'2');
 		checkFlg(summary,TempList,paymentInputList,'3');
        checkFlg(summaryMonney,TempList,paymentInputList,'4');
        checkFlg(dataType9,TempList,paymentInputList,'5');
        update paymentInputList;
        //ファイル名＋全体エラーメッセージ
        for(PaymentInput__c p:paymentInputList){
        	Rrows.payList.add(p.Filename__c+':'+p.errorMessage__c);
        }
        ///////////////////////////////////②//////////////////////////////
        /////////////////////////////////////③//////////////////////////////

        //照会番号の重複チェック
        //ファイル毎にループ
        for(Integer p=0;p<TempList.size();p++){
            //ファイルの中身をループ
            //logic    1file: at first we remove the record
            //                secondly,if there is still  the record
            //                we can sure that the record is repeated
            for(Integer k=0;k<TempList[p].size();k++){
 				TempList3[p].remove(k);
                if(TempList3[p].contains(TempList[p][k].referenceNo__c)){
                    TempList[p][k].errorFlg__c=true;
                    TempList[p][k].errorMessage__c='照会番号が重複するため、登録出来ません。';
                }
                if(k==TempList[p].size()-1){
                    TempList3[p].add(TempList[p][k].referenceNo__c);
                }else{
                    TempList3[p].add(k,TempList[p][k].referenceNo__c);
                }
            }
        }
        /////////////////////////////////////③//////////////////////////////
        /////////////////////////////////////④//////////////////////////////
        //全ての明細
        List<List<string>> allReferenceList=getAllReferenceList();
        List<string> referenceList=allReferenceList[0];
        //List<string> referenceNoList=allList[1];
        system.debug('5'+TempList);
        for(List<PaymentInputDetail__c> templist2:TempList){
            for(PaymentInputDetail__c temp : templist2){
                //照会番号がすでに存在する場合、更新する
                //if(referenceNoList.contains(temp.referenceNo__c)){
                //   temp.Id=idList.get(referenceNoList.indexOf(temp.referenceNo__c));
                //   paymentInputDetailUpdate.add(temp);
                //}else{
                //照会番号が存在しない場合、挿入する
                //    paymentInputDetailInsert.add(temp);
                //}
                ////照会番号がすでに存在する場合、
                if(referenceList.contains(temp.referenceNo__c)){
                    temp.errorFlg__c=true;
                    temp.errorMessage__c='照会番号がすでに登録しましたので、登録できません。';
                }
                paymentInputDetailInsert.add(temp);
            }
        }
		/////////////////////////////////////④//////////////////////////////
        system.debug('3');
 		system.debug(paymentInputDetailInsert);
		//system.debug(paymentInputDetailUpdate);
        insert paymentInputDetailInsert;
        //update paymentInputDetailUpdate;


        /////////////////////////////////////⑤//////////////////////////////
        //入金を更新
        Rrows =updatePayment(paymentInputList,paymentInputDetailInsert);
        List<Payment__c> pays = Rrows.paymentList;
        /////////////////////////////////////⑤//////////////////////////////
        /////////////////////////////////////⑥//////////////////////////////
        //入金に挿入したデータがある場合
        if(Rrows.rightRows!=0){
            system.debug('101');
            //入金で請求金を消し込み
            Dopayment2.executeKesikomi();
        }
        return Rrows;
    }
    
	@AuraEnabled
    public Static Rows updatePayment(List<PaymentInput__c> paymentInputList,List<PaymentInputDetail__c> paymentInputDetailInsert ) {
		Rows Rrows=new Rows();
        //取引先
		List<List<string>> allAccountList=getAllAccountList();
        List<string> IdList = allAccountList[0];
        List<string> addressList = allAccountList[1];
        
        //更新用
        List<PaymentInputDetail__c>	newDetailList= new List<PaymentInputDetail__c>();
		system.debug(paymentInputDetailInsert);
        
        for(PaymentInputDetail__c p:paymentInputDetailInsert){
            Payment__c payment = new Payment__c();
            //string adress=p.Bank_account_Nominee__c+p.Financial_Name__c+p.Financial_branch__c;
            string adress=p.Bank_account_Nominee__c;
            system.debug(adress.replace('"', ''));
            if(addressList.contains(adress.replace('"', ''))&&p.errorFlg__c==false){
                payment.Account__c=IdList.get(addressList.indexOf(adress.replace('"', '')));
                 //入金日
                payment.PaymentDate__c=p.PaymentDate__c;
                //入金
                payment.PaymentAmountInput__c=p.Payment__c;
                //入金取込詳細
                payment.relationPaymentDetail__c=p.Id;
                Rrows.paymentList.add(payment);
            }else{
            	//入金に入力できない場合、エラーとして処理
            	if(p.errorMessage__c==null||p.errorMessage__c==''){
            		p.errorMessage__c='振り込み先が合わないため、登録できません。';
            	}
            	Rrows.detailList.add(p);
            }
        }
        Rrows.rightRows=0;
        Rrows.errorRows=0;
        //入金に挿入した行数
		Rrows.rightRows=Rrows.paymentList.size();
		//入金に挿入しなかった行数
		Rrows.errorRows=paymentInputDetailInsert.size()-Rrows.rightRows;
		insert Rrows.paymentList;
		system.debug(Rrows.rightRows+'!'+Rrows.errorRows);
        for(Payment__c c:Rrows.paymentList){
            PaymentInputDetail__c newDetail=new PaymentInputDetail__c(Id=c.relationPaymentDetail__c);
            newDetail.RegistrationFlg__c=true;
            newDetailList.add(newDetail);
        }
        update newDetailList;
        system.debug(Rrows.paymentList);
        return Rrows;
    }

     private Static Date convertDate(string oldDate) {
        string year=oldDate.substring(0, 2);
        Integer base = 1989;
        base=base+Integer.valueOf(year)-1;
        string month= oldDate.substring(2,4);
        string day= oldDate.substring(4);
        return Date.newInstance(base,Integer.valueOf(month),Integer.valueOf(day));
    }

     private Static void checkFlg(Map<Integer, Boolean> flg,List<List<PaymentInputDetail__c>> TempList,List<PaymentInput__c> paymentInputList,string kind) {
        Integer ifile=0;
        string error='';
        for(Integer key : flg.keySet()){
            if(!flg.get(key)){
                //チェック失敗の場合,入金取込明細のフラグを全部trueに設定
                for(PaymentInputDetail__c p:TempList[key]){
                    //エラーあり
                    p.errorFlg__c=true;
                }
                if(kind=='1'){
                    error='振込CSVファイルのヘッダー【口座番号】が間違い　';
                }else if(kind=='2'){
                    error='振込CSVファイルの【合計】が存在しない　';
                }else if(kind=='3'){
                    error='振込CSVファイルの【合計件数】が間違い　';
                }else if(kind=='4'){
                    error='振込CSVファイルの【合計金額】が間違い　';
                }else if(kind=='5'){
                    error='振込CSVファイルの【エンドコード】が存在しない';
                }
                paymentInputList[ifile].errorMessage__c=error;
            }
            ifile=ifile+1;
        }
    }

}