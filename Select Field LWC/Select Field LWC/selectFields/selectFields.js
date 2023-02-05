import {CurrentPageReference} from 'lightning/navigation';
import { LightningElement, api, track, wire } from 'lwc';
import objectFields from '@salesforce/apex/SelectFieldsController.objectFields';
import getObjects from '@salesforce/apex/Utility.getObjects';
import exportCSV from '@salesforce/apex/Utility.exportCSV';
import saveRecord from '@salesforce/apex/SelectFieldsController.saveRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SelectFields extends LightningElement {

    recordId;
    @track lstQuestions = [];
    @track isSelectFieldScreen = true;
    @track isEditFieldScreen = false;
    @track fieldSetOptions = [];
    @track editfieldSetOptions = [];
    @track selectedFields = [];
    @track requiredFields = [];
    @track finalFields = [];
    @track lstObjectPicklist = [];
    @track showFields = false;
    sObjectName = '';
    @track isLoading = false;

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback(){
        this.isLoading = true;
        getObjects()
        .then((result)=>{
            //console.log('result==='+result);
            this.lstObjectPicklist = JSON.parse(result).lstObjectPicklist;
            this.isLoading = false;
        
        }).catch((error) => {
            this.isLoading = false;
            console.log("Error : "+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'ERROR!',
                message: error.message,
                variant: 'error'
            });
            this.dispatchEvent(evt);
        });

        
    }

    genericChange(e) {
        let index = e.target.dataset.index;
        
        if(this.finalFields[index].fieldType == 'number')
        {
            this.finalFields[index].numValue = e.target.value;
        }
        else if(this.finalFields[index].fieldType == 'checkbox')
        {
            this.finalFields[index].boolValue = e.target.checked;
        }
        else{
            //this.finalFields[index].textValue = e.detail.value;
            this.finalFields[index].textValue = e.target.value;
            console.log(JSON.stringify(this.finalFields[index]));
            console.log(e.detail.value);
        }
    }

    selectObject(event){
        this.sObjectName = event.target.value;
        this.requiredFields = [];
        this.selectedFields = [];
        this.getObjectFields(this.sObjectName);
    }

    selectExportFieldChange(event)          
    {
        let index = event.target.dataset.index;
        this.fieldSetOptions[index].validField = event.target.checked;
        console.log(JSON.stringify(this.fieldSetOptions[index]));
        //this.selectedFields.splice(index, 1); 
        this.selectedFields = [];
    }


    selectEditFieldChange(event)
    {
        let index = event.target.dataset.index;
        this.editfieldSetOptions[index].validField = event.target.checked;
        console.log(JSON.stringify(this.editfieldSetOptions[index]));
        //this.selectedFields.splice(index, 1); 
        this.selectedFields = [];
    }

    getObjectFields(sobjectName)
    {
        this.isLoading = true;

        objectFields({sObjectName: sobjectName})
        .then((result)=>{
            console.log('resultFields==='+result);
            let apexObj = JSON.parse(result);
            this.fieldSetOptions = apexObj.objfieldWrapper;
            //console.log('Question==='+JSON.stringify(this.fieldSetOptions));
            // for (let index = 0; index < this.fieldSetOptions.length; index++) {
            //     if(this.fieldSetOptions[index].required)
            //     {
            //         this.requiredFields.push(this.fieldSetOptions[index]);
            //     }
            // }
            this.showFields = true;
            this.isLoading = false;
        
        }).catch((error) => {
            
            this.isLoading = false;
            console.log("Error : "+JSON.stringify(error));
            const evt = new ShowToastEvent({
                title: 'ERROR!',
                message: JSON.stringify(error),
                variant: 'error'
            });
            this.dispatchEvent(evt);
        });
    }
    
    exportfieldSetHandle(){
        this.selectedFields = [];
    }

    editfieldSetHandle()
    {
        console.log('asdwasdwasdw');
        this.editfieldSetOptions = [];
        this.isLoading = true;
        for(let index = 0; index < this.fieldSetOptions.length; index++) 
        {
            if(!this.fieldSetOptions[index].isFormulaField){
                this.editfieldSetOptions.push(this.fieldSetOptions[index]);
            }
        }
        this.isLoading = false;
        console.log('editfieldSetOptions=== '+ JSON.stringify(this.editfieldSetOptions));
    }

    nextHandle()
    {
        if(this.isInputValid('.validate'))
        {
            console.log('asdasdasd');
            for(let index = 0; index < this.editfieldSetOptions.length; index++) 
            {
                if(this.editfieldSetOptions[index].validField){
                    this.selectedFields.push(this.editfieldSetOptions[index]);
                }
            }
            this.finalFields = this.selectedFields;
            console.log('finalFields=== '+ JSON.stringify(this.finalFields));
            //this.finalFields = this.requiredFields.concat(this.selectedFields);
            //this.isSelectFieldScreen = false;
            this.isEditFieldScreen = true;
        }
    }

    exportHandle()
    {
        for(let index = 0; index < this.fieldSetOptions.length; index++) 
        {
            if(this.fieldSetOptions[index].validField){
                this.selectedFields.push(this.fieldSetOptions[index]);
            }
        }
        if (this.selectedFields && this.selectedFields.length)
        {
            this.finalFields = this.selectedFields;

            exportCSV({JsWrapper : JSON.stringify(this.finalFields), sObjectAPIName : this.sObjectName})
            .then((result)=>{
                console.log('exportCSV==='+result);
                this.download(this.sObjectName+'.csv',result );
            
            }).catch((error) => {
                this.isLoading = false;
                console.log("Error : "+JSON.stringify(error));
                const evt = new ShowToastEvent({
                    title: 'ERROR!',
                    message: error.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
        }else{
            const evt = new ShowToastEvent({
                title: 'CAUTION!',
                message: 'Please select atleast one field to export!',
                variant: 'warning'
            });
            this.dispatchEvent(evt);
        }
    }


    download(filename, doc) {
        let downXMlfile = document.createElement('a');
        downXMlfile.setAttribute('href', 'data:text/csv;charset=utf-8,' + encodeURIComponent(doc));
        downXMlfile.setAttribute('download', filename);
        if (document.createEvent) {
            let event = document.createEvent('MouseEvents');
            event.initEvent('click', true, true);
            downXMlfile.dispatchEvent(event);
        }
        else {
            //error
        }
    }

    PreviousHandle()
    {
        this.isSelectFieldScreen = true;
        this.isEditFieldScreen = false;
        this.selectedFields = [];
    }


    saveHandle(){
        console.log(JSON.stringify(this.finalFields));
        if(this.isInputValid('.validate'))
        {
            saveRecord({jsonRecord: JSON.stringify(this.finalFields), sObjectAPIName : this.sObjectName})
            .then((result)=>{
                const evt = new ShowToastEvent({
                    title: 'Success!',
                    message: 'Record has been created successfully! Id-'+ result,
                    variant: 'success'
                });
                this.dispatchEvent(evt);
            
            }).catch((error) => {
                console.log("Error : "+JSON.stringify(error));
                const evt = new ShowToastEvent({
                    title: 'ERROR!',
                    message: JSON.stringify(error),
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
        }
    }

    isInputValid(selector) 
    {
        let isValid = true;
        let inputFields = this.template.querySelectorAll(selector);
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) 
            {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }
}