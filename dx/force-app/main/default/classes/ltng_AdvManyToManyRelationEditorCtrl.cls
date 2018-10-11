/**
 * Controller to define and edit the ltng_M2M_Relationship__c objects.
 * 
 * <p>This does not create the many to many relationship,
 * but simply defines it, so it can be easily shown to the end user.</p>
 * 
 * @class ltng_AdvManyToManyRelationEditorCtrl
 **/
public class ltng_AdvManyToManyRelationEditorCtrl {
    
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

        Map<String,FieldApiOption> potentialJunctionObjects = new Map<String,FieldApiOption>();
        Set<String> foundChildObjects = new Set<String>();
        
        Schema.DescribeSObjectResult childDescribe;
        Schema.DescribeFieldResult fieldDescribe;
        Schema.SObjectType[] fieldSObjectReferences;
        ManyToManyRelationOption m2mRelation;
        SObjectApiOption currentJunction;
        FieldApiOption currentFieldDescribe;
        FieldApiOption targetFieldDescribe;
        ManyToManyRelationOption currentRelationshipOption;

        for( Schema.ChildRelationship childRelation : leftObjectDescribe.getChildRelationships() ){
            childDescribe = childRelation.getChildSObject().getDescribe();
            fieldDescribe = childRelation.getField().getDescribe();

            /*
            if (childDescribe.getName() == 'ltng_M2M_AccountContactRelationship__c'){
                System.debug('\n\n\n\nTHIS ONE\n\n\n\n\n');
            }
            //System.debug(childDescribe);
            System.debug('object.isAccessible:' + childDescribe.isAccessible());
            System.debug('childRelation.getName:' + childDescribe.getName());
            System.debug('fieldLabel:' + fieldDescribe.getName());
            System.debug('isNamePointing:' + fieldDescribe.isNamePointing());
            System.debug('getReferenceTo:' + fieldDescribe.getReferenceTo());

            if (childDescribe.getName() == 'ltng_M2M_AccountContactRelationship__c'){
                System.debug('\n\n\n\nTHIS ONE\n\n\n\n\n');
            }
            */

            potentialJunctionObjects.put(childDescribe.getName(), new FieldApiOption(fieldDescribe.getLabel(), fieldDescribe.getName()));
        }

        for( Schema.ChildRelationship childRelation : rightObjectDescribe.getChildRelationships() ){
            childDescribe = childRelation.getChildSObject().getDescribe();

            //System.debug('childDescribe.getName:' + childDescribe.getName());
            //foundChildObjects.add(childDescribe.getName());

            //-- @TODO: Currently there is no known way to reduce the list
            //-- so it doesn't include the 'System' objects like Attachment, EmailMessage, FeedItem
            //-- without going through every field on each of those objects
            //-- to ensure that they have relations to both of these objects.
            //-- so for now, we will just ask the end user.

            //-- only continue if the child relation was found in both objects
            if (potentialJunctionObjects.containsKey(childDescribe.getName())) {
                fieldDescribe = childRelation.getField().getDescribe();

                //-- only continue if the field is different between the two
                //-- as otherwise we are dealing with one of those ubiquitous objects
                //-- like documents / emailTemplates etc.
                //-- that cannot be weeded out in any other way

                currentFieldDescribe = new FieldApiOption(fieldDescribe.getLabel(), fieldDescribe.getName());
                targetFieldDescribe = potentialJunctionObjects.get(childDescribe.getName());
                if(!currentFieldDescribe.optionApiName.equals(targetFieldDescribe.optionApiName)){
                    currentJunction = new SObjectApiOption(childDescribe.getLabel(), childDescribe.getName());

                    currentRelationshipOption = new ManyToManyRelationOption(currentJunction.optionLabel, currentJunction.optionApiName);
                    currentRelationshipOption.junctionObjectOption = currentJunction;
                    currentRelationshipOption.leftObjectOption = new SObjectApiOption(leftObjectDescribe.getLabel(), leftObjectDescribe.getName());
                    currentRelationshipOption.rightObjectOption = new SObjectApiOption(rightObjectDescribe.getLabel(), rightObjectDescribe.getName());

                    
                    currentRelationshipOption.leftObjectJunctionField = targetFieldDescribe;
                    currentRelationshipOption.rightObjectJunctionField = currentFieldDescribe;

                    results.add(currentRelationshipOption);
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

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Internal Classes used for communication
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

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