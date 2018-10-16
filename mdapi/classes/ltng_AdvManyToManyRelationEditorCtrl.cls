/**
 * Controller to define and edit the ltng_M2M_Relationship__c objects.
 * 
 * <p>This does not create the many to many relationship,
 * but simply defines it, so it can be easily shown to the end user.</p>
 * 
 * @class ltng_AdvManyToManyRelationEditorCtrl
 **/
public class ltng_AdvManyToManyRelationEditorCtrl {

    /** delimiter */
    public static final String FIELD_DELIMITER = '-';
    
    /** represents the error if the user is unable to get a list of sObjects */
    public static final String ERROR_CANNOT_LIST_SOBJECTS = 'Unable to access list of SObjects. Please contact your administrator';

    /**
     * List the SObjects available for start a Many to Many relationship definition
     */
    @AuraEnabled
    public static SObjectApiOption[] getListOfAllObjects(){
        SObjectApiOption[] results = new SObjectApiOption[]{
            new SObjectApiOption()
        };

        //-- for more please see:
        //-- https://developer.salesforce.com/docs/atlas.en-us.api_tooling.meta/api_tooling/tooling_api_objects_entitydefinition.htm

        try {
            EntityDefinition[] entities = [
                SELECT MasterLabel, QualifiedApiName
                FROM EntityDefinition
                WHERE IsRetrieveable = true
                order by MasterLabel
            ];
            for(EntityDefinition entity : entities){
                results.add(new SObjectApiOption(entity.MasterLabel, entity.QualifiedApiName));
            }
        } catch(Exception err){
            throw new AuraHandledException(ERROR_CANNOT_LIST_SOBJECTS);
        }

        //-- @POSTCONDITION: results includes a list of all SObjects we can choose from
        //-- with the API and Labels - available for selecting in a list.
        // System.debug('allSobjects available:' + results.size());
        // System.debug('allSobject options:' + results);

        return results;
    }

    /**
     * Determines the list of junction objects currently used for linking two objects together.
     * <p>This includes fields and other relation information</p>
     * <p>Note, this does not require that the junction object fields
     * are exactly the sObjects, only as long as the fields that relate
     * are not the same. (This weeds out standard objects like EmailTemplate, document, etc)</p>
     * @param leftSObject (String)
     * @param rightSObject (String)
     * @ return ManyToManyRelationOption[] - collection of relations (and related fields) that link those two objects.
     *  */    
    @AuraEnabled
    public static ManyToManyRelationOption[] getJunctionRelationships(String leftSObject, String rightSObject){
        ManyToManyRelationOption[] results = new ManyToManyRelationOption[]{};
        
        Schema.DescribeSObjectResult leftObjectDescribe = ltng_AdvManyToManyUtil.getSObjectDescription(leftSObject);
        Schema.DescribeSObjectResult rightObjectDescribe = ltng_AdvManyToManyUtil.getSObjectDescription(rightSObject);

        Map<String,FieldApiOption[]> potentialJunctionFields = new Map<String,FieldApiOption[]>();
        Set<String> foundChildObjects = new Set<String>();
        
        String sObjectName;
        Schema.DescribeSObjectResult childDescribe;
        Schema.DescribeFieldResult fieldDescribe;
        Schema.SObjectType[] fieldSObjectReferences;
        SObjectApiOption currentJunction;
        FieldApiOption[] matchingFieldOptions;
        ManyToManyRelationOption currentRelationshipOption;

        for( Schema.ChildRelationship childRelation : leftObjectDescribe.getChildRelationships() ){
            childDescribe = childRelation.getChildSObject().getDescribe();
            fieldDescribe = childRelation.getField().getDescribe();
            fieldSObjectReferences = fieldDescribe.getReferenceTo();

            //-- only add it to the list if the field references a single object (Master-Detail/)
            if(fieldSObjectReferences.size() == 1){
                //-- there can be multiple fields that relate to this object
                //-- like bill-to, ship-to, customerAuthorizedBy, etc.
                sObjectName = childDescribe.getName();
                if (!potentialJunctionFields.containsKey(sObjectName)) {
                    potentialJunctionFields.put(sObjectName, new FieldApiOption[]{});
                }

                //-- we know the object name of the possible junction,
                //-- and the field on the junction that points to the left object
                //-- so add it to the list in case there are multiple
                potentialJunctionFields.get(sObjectName).add(new FieldApiOption(fieldDescribe.getLabel(), fieldDescribe.getName()));
            }
        }

        for( Schema.ChildRelationship childRelation : rightObjectDescribe.getChildRelationships() ){
            childDescribe = childRelation.getChildSObject().getDescribe();

            //-- only continue if the child relation was found in both objects
            if (potentialJunctionFields.containsKey(childDescribe.getName())) {
                
                //-- ensure that the relationship is not a polymorphic field
                fieldDescribe = childRelation.getField().getDescribe();
                fieldSObjectReferences = fieldDescribe.getReferenceTo();

                if (fieldSObjectReferences.size() == 1){

                    //-- @TODO - move to a map of SObject,ManyToManyelationOption - to avoid for loop in for loop
                    //-- however, tests show that the gains from moving out to avoid the for in a for loop
                    //-- is worse in nearly all real-life tests
                    //-- because the code is either uses expensive clones in most cases or difficult to read
                    //-- so this has been de-prioritized for now.

                    currentJunction = new SObjectApiOption(childDescribe.getLabel(), childDescribe.getName());
                    matchingFieldOptions = potentialJunctionFields.get(currentJunction.optionApiName);
                    for (FieldApiOption leftJunctionField : matchingFieldOptions) {

                        //-- we know that the object references both the left and right sObjects
                        //-- and that the fields are different
                        //-- so package it up as a valid option to choose.

						currentRelationshipOption = new ManyToManyRelationOption(currentJunction.optionLabel, currentJunction.optionApiName);
						currentRelationshipOption.junctionObjectOption = currentJunction;
						currentRelationshipOption.leftObjectOption = new SObjectApiOption(leftObjectDescribe.getLabel(), leftObjectDescribe.getName());
						currentRelationshipOption.rightObjectOption = new SObjectApiOption(rightObjectDescribe.getLabel(), rightObjectDescribe.getName());
	
						currentRelationshipOption.leftObjectJunctionField = leftJunctionField;
						currentRelationshipOption.rightObjectJunctionField = new FieldApiOption(fieldDescribe.getLabel(), fieldDescribe.getName());

                        //-- make a unique identifier
                        currentRelationshipOption.optionApiName = currentRelationshipOption.junctionObjectOption.optionApiName + FIELD_DELIMITER +
                            currentRelationshipOption.leftObjectJunctionField.optionApiName + FIELD_DELIMITER +
                            currentRelationshipOption.rightObjectJunctionField.optionApiName;
                        
                        results.add(currentRelationshipOption);
                    }
                }
            }
        }

        if (results.size() > 1){
            results.add(0,new ManyToManyRelationOption());
        }
        
        return results;
    }

    /**
     * Save the ManyToMany Relationship record
     **/
    @AuraEnabled
    public static ltng_M2M_Relationship__c saveM2MRelation(ltng_M2M_Relationship__c relation) {
        ltng_M2M_Relationship__c results;
        
        try {
            upsert relation;
        } catch(Exception err){
            throw new AuraHandledException('Exception occurred when processing: saveM2MRelation:' + err.getMessage());
        }
        
        return(results);
    }

    /**
     * Determines the list of fields to choose from on a given sObject
     * @param sObjectApiName (String)
     * @return DualListBoxOption[]
     **/
    /**
     * Description for method
     **/
    @AuraEnabled
    public static DualListBoxOption[] getSObjectFieldOptions(String sObjectApiName) {
        DualListBoxOption[] results = new DualListBoxOption[]{};

        Schema.DescribeSObjectResult objectDescribe = ltng_AdvManyToManyUtil.getSObjectDescription(sObjectApiName);
        Map<String, Schema.SObjectField> objectFields = objectDescribe.fields.getMap();
        Schema.DescribeFieldResult fieldDescribe;
        Set<String> fieldNames = objectFields.keySet();
        DualListBoxOption option;

        for (String fieldName : fieldNames){
            fieldDescribe = objectFields.get(fieldName).getDescribe();
            results.add(new DualListBoxOption(
                fieldDescribe.getLabel() + ' (' + fieldDescribe.getName() + ')',
                fieldDescribe.getName()
            ));
        }

        results.sort();

        try {
            
        } catch(Exception err){
            throw new AuraHandledException('Exception occurred when processing: getSObjectFieldOptions');
        }
        
        return(results);
    }
    

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Internal Classes used for communication
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

    /**
     * Represents an option for the Dual List Box
     */
    public class DualListBoxOption implements Comparable{
        @AuraEnabled
        public String label;

        @AuraEnabled
        public String value;

        public DualListBoxOption(String label, String value){
            this.label = label;
            this.value = value;
        }

        public Integer compareTo(Object otherComparable) {
            if (otherComparable == null || !(otherComparable instanceOf DualListBoxOption)) {
                return (1);
            } else {
                DualListBoxOption otherOption = (DualListBoxOption)otherComparable;
                if (this.label == otherOption.label) {
                    return 0;
                } else if (this.label > otherOption.label){
                    return 1;
                } else {
                    return -1;
                }
            }
        }
    }

    /**
     * Represents an SObject option
     **/
    public class FieldApiOption extends ltng_AdvManyToManyUtil.ApiOption {
        public FieldApiOption(){
            super();
        }

        public FieldApiOption(String label, String apiName){
            super(label, apiName);
        }
    }

    /**
     * Represents an SObject option
     **/
    public class SObjectApiOption extends ltng_AdvManyToManyUtil.ApiOption {
        public SObjectApiOption(){
            super();
        }

        public SObjectApiOption(String label, String apiName){
            super(label, apiName);
        }
    }

    /**
     * Represents a Many to Many relationship
     * that is available for selecting.
     * <p>Used by the RelationEditor, representing a complete option.
     * (often after the left and right objects are chosen.)</p>
     */
    public class ManyToManyRelationOption extends ltng_AdvManyToManyUtil.ApiOption {
        @AuraEnabled
        public ApiOption leftObjectOption;

        @AuraEnabled
        public ApiOption rightObjectOption;

        @AuraEnabled
        public ApiOption junctionObjectOption;

        @AuraEnabled
        public ApiOption leftObjectJunctionField;

        @AuraEnabled
        public ApiOption rightObjectJunctionField;
        /*
        @AuraEnabled
        public String optionLabel;

        @AuraEnabled
        public String optionApiName;
        */
        public ManyToManyRelationOption(){
            super();
        }

        public ManyToManyRelationOption(String label, String apiName){
            super(label, apiName);
        }
    }
}