/** 
 * 見積詳細レコード画面において、「成約」クイックアクションより、成約コピーコンポーネントに向けコントローラです。
 */
public with sharing class SignedAgreementController {
	/** 
     * 初期化する時、見積・契約の情報を取得する。
     */
	@AuraEnabled
    public static SignInfo getInitInfo(String estimateId){
    	SignInfo info = new SignInfo();
    	info.estimate = CommonUntil.getEstimateById(estimateId);
    	info.recordType = ProductEditListController.getRecordTypeId();
        return info;
        
    }
    
	/** 
     * 初期化する時、見積・契約の情報を取得する。
     */
	@AuraEnabled
    public static ACCOUNT getAccoutInfoById(String accountId){
        return [SELECT Id,Name,Contact_Position__c,Contact_name__c,ShippingState,ShippingCity,ShippingStreet FROM ACCOUNT WHERE Id = :accountId];
    }


     /**
     * バッチ小EXCLEの見積添付ファイルへ処理
     */
    @AuraEnabled
    public static List<Id> saveBatchFiles(String files,String estimateId) {
        system.debug('files:'+files);  
        
		List<ContentVersion> conObjectList=new List<ContentVersion>();
        //ファイルの中身をゲット
        List<PayFile> fileList = (List<PayFile>)System.JSON.deserializeStrict(files,List<PayFile>.Class);
        for(PayFile file: fileList){
            //ファイル名
            ContentVersion conObject=new ContentVersion();
            conObject.title=file.name;
            conObject.PathOnClient=file.name;
        	conObject.ContentUrl='';
        	String size = file.size;
        	
        	string base64=file.content.split('base64,')[1];
            conObject.versiondata=EncodingUtil.base64Decode(base64);            
            conObjectList.add(conObject);
        }
        
		insert conObjectList;
		
		string condition='';        
        for(ContentVersion conObject:conObjectList){
             condition=condition+'\''+conObject.Id+'\',';
        }
        if(condition.length()>1){
            condition='WHERE ID in ('+condition.substring(0, condition.length()-1)+')';
        }
       string sql='SELECT Id,ContentDocumentId FROM ContentVersion '+condition;
       List<ContentVersion> conObjectTemp =Database.query(sql);
       
       List<ContentDocumentLink>  ctnLinkList= new List<ContentDocumentLink>();
       for(ContentVersion cyp:conObjectTemp){
       		ContentDocumentLink clk= new ContentDocumentLink();
       		clk.ShareType='V';
       		clk.LinkedEntityId=estimateId;
       		clk.ContentDocumentId=cyp.ContentDocumentId;
       		ctnLinkList.add(clk);
       }
       insert ctnLinkList;
       return null;
    }
    
    public class SignInfo {
        /**
         * 初期化データ
         */
        @AuraEnabled
        public Estimate__c estimate { set; get; }
        /**
         * レコードタイプ
         */
        @AuraEnabled
        public RecordType[] recordType { set; get; }
    }
    
    
}