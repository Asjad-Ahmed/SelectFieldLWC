public class Utility {

    @AuraEnabled
    public static String getObjects(){
        //Map<String, List<String> sObjFieldMap = new Map<String, List<String>();
        UtilityMainWrapper objMain = new UtilityMainWrapper();
        objMain.lstObjectPicklist = new List<ObjectPicklist>();
        map<string, SObjectType> objs = schema.getGlobalDescribe();
        for(SObjectType eachSobjectType : objs.values())
        {
            if(eachSobjectType.getDescribe().isCreateable() && eachSobjectType.getDescribe().isSearchable())
            {
                ObjectPicklist obj = new ObjectPicklist();
                obj.label = eachSobjectType.getDescribe().getLabel();
                obj.value = eachSobjectType.getDescribe().getName();
                objMain.lstObjectPicklist.add(obj);
            }
        }
        return JSON.serialize(objMain);
    }

    @AuraEnabled
    public static string exportCSV(String JsWrapper, String sObjectAPIName)
    {
        List<SelectFieldsController.FieldWrapper> lstFieldWrapperValues = new List<SelectFieldsController.FieldWrapper>();
        String generatedCSVFile ='';
        if (JsWrapper != null && JsWrapper != '' && sObjectAPIName != null && sObjectAPIName != '') 
        {
            String fileRow = '';
            String fields = '';
            String sQuery = '';
            List<String> lstColumsFields = new List<String>();
            List<String> lstQueryFields = new List<String>();
            lstQueryFields.add('Id');
            lstFieldWrapperValues = (list<SelectFieldsController.FieldWrapper>)JSON.deserialize(JsWrapper, list<SelectFieldsController.FieldWrapper>.class);
            for(SelectFieldsController.FieldWrapper FWObj : lstFieldWrapperValues)
            {
                lstColumsFields.add(FWObj.fieldName);
                lstQueryFields.add(FWObj.fieldAPIName);
            }
            generatedCSVFile = 'Id,'+ String.join(lstColumsFields, ',') + '\n';
            fields = String.join(lstQueryFields, ',');
            sQuery = 'SELECT '+ fields + ' FROM '+sObjectAPIName+' LIMIT 10000';
            system.debug(sQuery);
            for (SObject sObj : database.query(sQuery))  
            {
                fileRow = '';
                for (String fieldName : lstQueryFields) 
                {
                    fileRow = fileRow +','+String.ValueOf(sObj.get(fieldName)) ;
                }
                fileRow = fileRow.replaceFirst(',','');
                generatedCSVFile = generatedCSVFile + fileRow + '\n';
                //system.debug(sObj);
            }
            System.debug('=== '+generatedCSVFile);
        }
        return generatedCSVFile;
    } 
        
   

    public class UtilityMainWrapper{
        List<ObjectPicklist> lstObjectPicklist;
    }
    public class ObjectPicklist{
        public String label;
        public String value;
    }
}