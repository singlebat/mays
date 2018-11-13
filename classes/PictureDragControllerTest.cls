@isTest
private class PictureDragControllerTest {

    public InventoryProduct__c      aContac   {get; set;}
    public Attachment   aAttachment     {get; set;}
    
    public void generateContact(){

        this.aContac   = new InventoryProduct__c();
        this.aContac.PictureURL1__c   = 'Test'; 
        
        insert this.aContac;

        this.aAttachment = new Attachment();
        this.aAttachment.Body = Blob.valueOf('String');
    }
    
    public static PictureDragControllerTest generateTest(){
        PictureDragControllerTest e = new PictureDragControllerTest();
        e.generateContact();
        return e;
    }

    static testMethod void test_all() {

        Test.startTest();
        PictureDragControllerTest e = PictureDragControllerTest.generateTest();
        
        
        Id parentId = e.aContac.Id;
        //  test getProfilePicture
        
        String fileName = 'tDsri7H';
        String base64Data = '5gQiV0E';
        String contentType = 'image/png';
        //  test saveAttachment
        //  saveAttachment(Id parentId, String fileName, String base64Data, String contentType)
        PictureDragController.saveAttachment(parentId,fileName,base64Data,contentType,'InventoryProduct__c');

        try{
            PictureDragController.getProfilePicture(parentId);
        }catch(Exception ex){

        }
        
        Test.stopTest();

    }

}