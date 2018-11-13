public abstract class PagingPdfAbstractController {
	
    //ページ分けて、Maxのデーターを設定のため
    public Final Static Integer maxMeisaiSize = 10;
    
    /** 
     * PDFデータを検索
     */
    abstract void getPDFData(String Id , String deliveryTime2);
    
    /** 
     * ページング処理
     */
    protected List<pageTotal> getPageTotalByList(List<OpportunityProduct__c> meisaiList){
        Integer yuSu = math.mod(meisaiList.size(), maxMeisaiSize);
        Integer remainder = 0;
        if(yuSu != 0){
            remainder = maxMeisaiSize - yuSu;
        }
        for (Integer i = 0;i<remainder;i++){
            meisaiList.add(new OpportunityProduct__c());
        }
        List<pageTotal> pageTotalList = new List<pageTotal>();
        //最终的list
        pageTotalList.add(new pageTotal());
        Integer index = 0;
        for (OpportunityProduct__c dRecord: meisaiList) {
            pageTotal lastPageTotal = new pageTotal();
            if(index == maxMeisaiSize){
                pageTotalList.add(new pageTotal());
                index = 0;
            }
            lastPageTotal = pageTotalList[pageTotalList.size()-1];
            lastPageTotal.totax += (dRecord.ProductListPrice__c == null ? 0 : dRecord.ProductListPrice__c)*(dRecord.Purchase__r.Estimate__r.TAX__c==null?1:dRecord.Purchase__r.Estimate__r.TAX__c)*0.01;
            lastPageTotal.total += dRecord.ProductListPrice__c == null ? 0 : dRecord.ProductListPrice__c;
            lastPageTotal.productList.add(dRecord);
            index ++;
        }
        return pageTotalList;
    }
    
    /** 
     * ページング処理
     */
    public class pageTotal{
        public Decimal total{get;set;}
        public Decimal totax{get;set;}
        public List<OpportunityProduct__c> productList {get;set;}
        
        public pageTotal(){
            total = 0;
            totax = 0;
            productList = new List<OpportunityProduct__c>();
        }
    }
}