/**
 * @description Helper function used to convert an object that has key value pairs where
 * the value is an object with a value property, i.e. {value: {value:'', displayValue:''}},
 * into an object that has primitives as values: {value: ''}.
 * @param obj The object that has value objects.
 * @returns An object that has primitives as values, derived from the "value" property of
 * the fields on the passed in object.
 */
import GeFormService from 'c/geFormService';
import {isEmptyObject, isNotEmpty} from 'c/utilCommon';

export function flatten(obj) {
    let flatObj = {};
    for (const [key, value] of Object.entries(obj)) {
        if (value !== null && value !== undefined && value.hasOwnProperty('value')) {
            flatObj[key] = value.value;
        } else {
            flatObj[key] = value;
        }
    }
    return flatObj;
}

export function convertBDIToWidgetJson(additionalObjectJson) {
    const additionalObjects = JSON.parse(additionalObjectJson);

    if (isEmptyObject(additionalObjects) ||
        !additionalObjects.hasOwnProperty('dynamicSourceByObjMappingDevName')) {

        return;
    }

    let targetFieldsByObjectDevName = {};
    Object.values(additionalObjects.dynamicSourceByObjMappingDevName).forEach(dynamicSourceValue => {
        let fieldMappingsForObjectDevName = GeFormService.fieldMappingsForObjectMappingDevName(dynamicSourceValue.objectMappingTemplateDevName)
            .filter(fieldMapping => {
                return Object.keys(dynamicSourceValue.sourceObj)
                    .filter(sourceObjKey => isNotEmpty(dynamicSourceValue.sourceObj[sourceObjKey]))
                    .includes(fieldMapping.Source_Field_API_Name);
            });

        let targetFieldApiNameBySourceFieldApiName = {};

        fieldMappingsForObjectDevName.forEach(fieldMapping => {
            targetFieldApiNameBySourceFieldApiName[fieldMapping.Source_Field_API_Name] = fieldMapping.Target_Field_API_Name
        });

        if (!targetFieldsByObjectDevName.hasOwnProperty(dynamicSourceValue.objectMappingTemplateDevName)) {
            targetFieldsByObjectDevName[dynamicSourceValue.objectMappingTemplateDevName] = []
        }

        const simplifiedObjectForObjectDevName = createSimplifiedObjectForObjectDevName(targetFieldApiNameBySourceFieldApiName, dynamicSourceValue);
        targetFieldsByObjectDevName[dynamicSourceValue.objectMappingTemplateDevName].push(simplifiedObjectForObjectDevName);
    });

    return JSON.stringify(targetFieldsByObjectDevName);
}

function createSimplifiedObjectForObjectDevName(targetFieldApiNameBySourceFieldApiName, dynamicSourceValue) {
    let simplifiedObjectForObjectDevName = {
        attributes: {
            type: GeFormService.getObjectMapping(dynamicSourceValue.objectMappingTemplateDevName).Object_API_Name
        }
    };

    Object.keys(dynamicSourceValue.sourceObj)
        .filter(sourceField => isNotEmpty(targetFieldApiNameBySourceFieldApiName[sourceField]))
        .forEach(sourceFieldKey => {
            simplifiedObjectForObjectDevName[ targetFieldApiNameBySourceFieldApiName[sourceFieldKey] ] = dynamicSourceValue.sourceObj[sourceFieldKey]
        });

    return simplifiedObjectForObjectDevName;
}

