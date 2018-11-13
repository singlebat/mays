/** 
 * ツールクラス
 */
public with sharing class ToolsClass {

   
       /**
     * 共通の変更レート
     * 
     * @param  strContext     内容
     * @param  rate           レート
     * @param  maxByteLength  最大byte数
     * @param  maxLineCnt     最大行数
     * @return                変更したレート
     */

    public static Decimal getCommonRate(String strContext, Decimal rate, Decimal maxByteLength, Decimal maxLineCnt) {
        // 変更した後の内容
        String strUpdated = kaigyo(strContext, maxByteLength/rate);
        // 改行数
        Integer kaigyoCnt = strUpdated.countMatches('\n');
        kaigyoCnt++;
        // 普通の場合最大8行まで
        if (kaigyoCnt*rate == maxLineCnt || rate == 1) {
            return rate;
        }
        // 8行より大きい場合、一ステップ下がる
        if (kaigyoCnt*rate > maxLineCnt) {
            return rate - 0.01;
        }
        // 再帰り
        return getCommonRate(strContext, rate + 0.01, maxByteLength, maxLineCnt);
    }

    public static String getHtmlSpanStrByRate(String strContext,Decimal maxByteLength, Decimal maxLineCnt,Decimal fontSize){
        if (String.isEmpty(strContext)) {
            return null;
        }
        String tempStr = kaigyo(strContext,maxByteLength);
        // 改行数
        Integer kaigyoCnt = tempStr.countMatches('\n');
        // 行数(改行数 + 1)
        kaigyoCnt++;
        Decimal rate = 1;

        if (kaigyoCnt > maxLineCnt) {
            rate = getCommonRate(strContext, (maxLineCnt / Decimal.valueOf(kaigyoCnt)),maxByteLength,maxLineCnt);
            tempStr = kaigyo(strContext,maxByteLength/rate);
        }
         tempstr = '<pre style=\'font-size:' + (rate * fontSize) + 'px;\'>' + tempStr.replaceAll('\n','<br>') + '</pre>';
         tempstr = '<pre style=\'font-size:' + (rate * fontSize) + 'px;\'>' + tempStr+ '</pre>';
        return tempstr;
    }


      /**
     * 改行
     * 
     * @param  motoStr       元文字
     * @param  maxByteLength byteの文字数
     * @return               改行文字
     */
    public static String kaigyo(String motoStr, Decimal maxByteLength) {
        if (String.isEmpty(motoStr)) return motoStr; 
        String rtnValue = '';
        Decimal oneSize = 0;

        for (Integer i = 0; i < motoStr.length(); i++) {
            //一文字取得
            String one = motoStr.substring(i, (i+1) ) ;
            if (one == '\n') {
                oneSize = -1.01;
            }
            rtnValue += one;
            //一文字バイト数計算
            oneSize += getBytes(one);
            if (oneSize >= maxByteLength) {
                rtnValue += '\n';
                oneSize = 0;
            }
        }

        return rtnValue;
    }


        /**
     * byte数を取得する
     * 
     * @param  motoStr 元文字
     * @return         byte数
     */
    public static Decimal getBytes(String motoStr) {
        if (String.isEmpty(motoStr)) {
            return 0;
        }
        Integer length = motoStr.length();
        Decimal retBytes = 0;
        for (Integer i = 0; i < length; i++) {
            Decimal tempBytes = Blob.valueOf(motoStr.substring(i, (i+1))).size();
            if (tempBytes > 2) {
                tempBytes = 1.8;
            } else {
                tempBytes = 1.01;
            }
            retBytes += tempBytes;
        }
        return retBytes;
    }


}