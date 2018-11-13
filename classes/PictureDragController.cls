/** 
 * 商品マスタ、在庫商品詳細レコード画面において、画像をドラッグコンポーネントに向けコントローラ
 */
public class PictureDragController {

    @AuraEnabled
    public static List<ContentVersion> getProfilePicture(Id parentId) {
        List<ContentDocumentLink> contentLinkList = [SELECT Id,LinkedEntityId,ContentDocument.Title,ContentDocument.FileType,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: parentId AND ContentDocument.FileType IN ('JPG','PNG','GIF')];

        Set<Id> DocumentIdList = new Set<Id>();
        for (ContentDocumentLink documentLink : contentLinkList) {
            DocumentIdList.add(documentLink.ContentDocumentId);
        }

        List<ContentVersion> ContentVersionList = [SELECT Id,FileType,ContentDocumentId,MainImgTime__c FROM ContentVersion WHERE ContentDocumentId IN: DocumentIdList ORDER BY MainImgTime__c DESC NULLS LAST];

        return ContentVersionList;

    }

    
    @AuraEnabled
    public static Id saveAttachment(Id parentId, String fileName, String base64Data, String contentType, String sobjectName) {
        ContentVersion conObject=new ContentVersion();

        conObject.MainImgTime__c = System.now();
        conObject.title=fileName;
        
        conObject.PathOnClient=fileName;
        conObject.ContentUrl='';

        conObject.versiondata=EncodingUtil.base64Decode(base64Data);
        // ファイルにINSERT
        insert conObject;

        conObject = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id =: conObject.Id];

        insert new ContentDocumentLink(LinkedEntityId=parentId,ContentDocumentId=conObject.ContentDocumentId,ShareType='V');

        if (sobjectName == 'InventoryProduct__c') {
            update new InventoryProduct__c(Id=parentId,PictureURL1__c='/sfc/servlet.shepherd/version/download/'+conObject.Id);
        } else if (sobjectName == 'CustomObjectProductMaster__c') {
            update new CustomObjectProductMaster__c(Id=parentId,PictureURL1__c='/sfc/servlet.shepherd/version/download/'+conObject.Id);
        }

        return conObject.Id;
    }
}