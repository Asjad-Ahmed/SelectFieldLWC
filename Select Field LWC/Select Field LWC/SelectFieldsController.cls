/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-14-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/


public class SelectFieldsController {
   @AuraEnabled
   public static string objectFields(String sObjectName)
   {
        try {
            System.debug('Start----'+limits.getCpuTime());
            //List<FieldWrapper> lstFieldWrapper = new List<FieldWrapper>();
            //Id recordId = Id.valueOf(strRecordId);
            SObjectType SObjectType = Schema.getGlobalDescribe().get(sObjectName);
            //String sObjectName = recordId.getSObjectType().getDescribe().getName();
            Map<String, Schema.SObjectField> objectFieldsMap = SObjectType.getDescribe().fields.getMap();
            System.debug('objectFieldsMap++'+ objectFieldsMap.keySet());

            MainWrapper objMainWrapper = new MainWrapper();
            objMainWrapper.sObjectAPIName = sObjectName;
            objMainWrapper.objfieldWrapper = new List<FieldWrapper>();
          

            for (Schema.SObjectField field : objectFieldsMap.values()) {
                FieldWrapper eachFieldWrapper = new FieldWrapper();
                eachFieldWrapper.isFormulaField = false;
                eachFieldWrapper.validField = false;
                eachFieldWrapper.isPicklist = false;
                eachFieldWrapper.isReference = false;
                eachFieldWrapper.required = false;
                if(field.getDescribe().isAccessible() && !field.getDescribe().isUpdateable() && !field.getDescribe().isCreateable() && !(field.getDescribe().getName() == 'Id'))
                {
                    eachFieldWrapper.isFormulaField = true;
                }
                Schema.DescribeFieldResult desribeResult = field.getDescribe();
                if( desribeResult.isCreateable() && !desribeResult.isNillable() && !desribeResult.isDefaultedOnCreate())
                {
                    eachFieldWrapper.required = true;
                    //eachFieldWrapper.validField = true;
                }
                eachFieldWrapper.fieldName = field.getDescribe().getLabel();
                eachFieldWrapper.fieldAPIName = field.getDescribe().getName();
                String strType = String.valueOf(field.getDescribe().getType());
                system.debug('strTypee=='+strType);
                system.debug('eachFieldWrapper.fieldName=='+eachFieldWrapper.fieldName);
                
                switch on strType 
                {
                    when 'EMAIL' {
                        eachFieldWrapper.fieldType = 'email';
                    }
                    when 'BOOLEAN' {
                        eachFieldWrapper.fieldType = 'checkbox';
                    }
                    when 'DATE' {
                        eachFieldWrapper.fieldType = 'date';
                    }
                    when 'DATETIME' {
                        eachFieldWrapper.fieldType = 'datetime';
                    }
                    when 'PICKLIST' {
                        eachFieldWrapper.fieldType = 'combobox';
                        eachFieldWrapper.isPicklist = true;
                        eachFieldWrapper.lstPicklist = new List<PicklistWrapper>();
                        eachFieldWrapper.lstPicklist = getPickListValue(sObjectName, eachFieldWrapper.fieldAPIName);
                    }
                    when 'REFERENCE' {
                        eachFieldWrapper.isReference = true;
                        eachFieldWrapper.fieldType = 'text';
                    }
                    when 'DOUBLE' {
                        eachFieldWrapper.fieldType = 'number';
                    }
                    when 'INTEGER' {
                        eachFieldWrapper.fieldType = 'number';
                    }
                    when 'PERCENT' {
                        eachFieldWrapper.fieldType = 'number';
                        
                    }
                    when 'CURRENCY' {
                        eachFieldWrapper.fieldType = 'number';
                       
                    }
                    when else {
                        eachFieldWrapper.fieldType = 'text';
                    }
                }

                objMainWrapper.objfieldWrapper.add(eachFieldWrapper);
            }
            System.debug('objMainWrapper----'+objMainWrapper);
            System.debug('End----'+limits.getCpuTime());
            return JSON.serialize(objMainWrapper);
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    public static List<PicklistWrapper> getPickListValue(string objectApiName, string fieldApiName){
        List<PicklistWrapper> objWrap= new List<PicklistWrapper>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectApiName);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListObj : ple)
        {
            PicklistWrapper dwObj = new PicklistWrapper();
            dwObj.label = pickListObj.label;
            dwObj.value = pickListObj.value;
            objWrap.add(dwObj);
        }
        return objWrap;
    }

    @AuraEnabled
    public static string saveRecord(String jsonRecord, String sObjectAPIName){
        try {
            objectFields('Lead');
            objectFields('Lead');
            List<FieldWrapper> lstFieldWrapperValues = new List<FieldWrapper>();
            if (jsonRecord != null && jsonRecord != '' && sObjectAPIName != null && sObjectAPIName != '') 
            {
                lstFieldWrapperValues = (list<FieldWrapper>)JSON.deserialize(jsonRecord, list<FieldWrapper>.class);
                System.debug('lstFieldWrapperValues=== '+lstFieldWrapperValues);
                Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectAPIName);
                SObject sObj = sObjType.newSObject();
                //
                for (FieldWrapper FWObj : lstFieldWrapperValues) 
                {
                    system.debug('FWObj.fieldType=='+FWObj.fieldType);
                    switch on FWObj.fieldType {
                        when 'checkbox' {
                            sObj.put(FWObj.fieldAPIName, FWObj.boolValue);
                        }
                        when 'date' {

                        }
                        when 'datetime' {
                            
                        }
                        when 'number' {
                            sObj.put(FWObj.fieldAPIName, FWObj.numValue);
                        }
                        when else {
                            sObj.put(FWObj.fieldAPIName, FWObj.textValue);
                        }
                    }
                }
                System.debug(sObj);
                insert sObj;
                return sObj.Id;
            }
            return 'Some Error Occurred!!';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class MainWrapper{
        public List<FieldWrapper> objfieldWrapper;
        public string sObjectAPIName;
        //public List<FieldSetOptionsWrapper> objFieldSetOptions;
    }

    public class FieldWrapper{
        public string fieldName;
        public string fieldAPIName;
        public string fieldType;
        public string textValue;
        public boolean validField;
        public boolean isPicklist;
        public boolean required;
        public boolean boolValue;
        public boolean isReference;
        public boolean isFormulaField;
        public double numValue;
        public List<PicklistWrapper> lstPicklist;
    }

    public class PicklistWrapper{
        public string label;
        public String value;
    }
}