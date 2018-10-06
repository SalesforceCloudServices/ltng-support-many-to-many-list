/**
 * Controller for managing many to many relationships.
 * @class ltng_ManyToManyCtrl
 ltng_ManyToManyCtrl
 **/
public with sharing class ltng_ManyToManyCtrl {

    /** represents no selection **/
    public static final String NO_SELECTION = '-No Selection-';
    public static final String NO_SELECTION_VALUE = '';

    /** Templated query for finding children of a related record */
    public static final String LIST_CHILDREN_QUERY = 'SELECT Id, {0} FROM {1} WHERE {2} = :recordId';

    /** @TODO: move to working with the soql to get the relationships */
    public static final Map<String,ObjectMapping> OBJECT_MAPS = getObjectMaps();

    private static Map<String,ObjectMapping> getObjectMaps(){
        //-- @TODO: reduce to a single entry and allow for flipping
        Map<String,ObjectMapping> result = new Map<String,ObjectMapping>();
        result.put('ltng_M2M_Account__c', new ObjectMapping('ltng_M2M_Account__c', 'ltng_M2M_Contact__c', 'ltng_M2M_AccountContactRelationship__c'));
        result.put('ltng_M2M_Contact__c', new ObjectMapping('ltng_M2M_Contact__c', 'ltng_M2M_Account__c', 'ltng_M2M_AccountContactRelationship__c'));
        return result;
    }

    /**
     * List the SObjects available for start a Many to Many relationship definition
     */
    @AuraEnabled
    public static ApiOption[] getListOfAllObjects(){
        ApiOption[] results = new ApiOption[]{
            new ApiOption()
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
            System.debug('entities.length:' + entities.size());
            for(EntityDefinition entity : entities){
                results.add(new ApiOption(entity.MasterLabel, entity.QualifiedApiName));
            }
        } catch(Exception err){
            throw new AuraHandledException('Unable to access list of SObjects. Please contact your administrator');
        }

        return results;
    }

    public class ApiOption {
        @AuraEnabled
        public String optionLabel;

        @AuraEnabled
        public String optionApiName;

        public ApiOption(){
            this(NO_SELECTION, NO_SELECTION_VALUE);
        }

        public ApiOption(String label, String apiName){
            this.optionLabel = label;
            this.optionApiName = apiName;
        }
    }

    public class ManyToManyRelationOption {
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

        @AuraEnabled
        public String optionLabel;

        @AuraEnabled
        public String optionApiName;

        public ManyToManyRelationOption(){
            this(NO_SELECTION, NO_SELECTION_VALUE);
        }

        public ManyToManyRelationOption(String label, String apiName){
            this.optionLabel = label;
            this.optionApiName = apiName;
        }
    }

    /**
     * List the SObjects that have a child relationship with the selected object.
     * @param selectedSObject (String)
     * @return ApiOption[] - collection of SObjects that are child related to that object.
     **/
    @AuraEnabled
    public static ApiOption[] getChildRelationships(String selectedSObject) {
        ApiOption[] results = new ApiOption[]{};

        Schema.DescribeSObjectResult sobjectDescribe = getSObjectDescription(selectedSObject);

        Map<String,ApiOption[]> potentialJunctionObjects = new Map<String,ApiOption[]>();
        
        Schema.DescribeSObjectResult childDescribe;
        for( Schema.ChildRelationship childRelation : sobjectDescribe.getChildRelationships() ){
            childDescribe = childRelation.getChildSObject().getDescribe();

            results.add(new ApiOption(childDescribe.getLabel(), childDescribe.getName()));
        }

        //try {
        //    
        //} catch(Exception err){
        //    throw new AuraHandledException('Exception occurred when processing: ');
        //}
        
        return(results);
    }


    @AuraEnabled
    public static ManyToManyRelationOption[] getJunctionRelationships(String leftSObject, String rightSObject){
        ManyToManyRelationOption[] results = new ManyToManyRelationOption[]{};
        
        Schema.DescribeSObjectResult leftObjectDescribe = getSObjectDescription(leftSObject);
        Schema.DescribeSObjectResult rightObjectDescribe = getSObjectDescription(rightSObject);

        Map<String,ApiOption> potentialJunctionObjects = new Map<String,ApiOption>();
        Set<String> foundChildObjects = new Set<String>();
        
        Schema.DescribeSObjectResult childDescribe;
        Schema.DescribeFieldResult fieldDescribe;
        ManyToManyRelationOption m2mRelation;
        ApiOption currentOption;
        ApiOption currentFieldDescribe;
        ApiOption targetFieldDescribe;
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

            potentialJunctionObjects.put(childDescribe.getName(), new ApiOption(fieldDescribe.getLabel(), fieldDescribe.getName()));
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

                currentFieldDescribe = new ApiOption(fieldDescribe.getLabel(), fieldDescribe.getName());
                targetFieldDescribe = potentialJunctionObjects.get(childDescribe.getName());
                if(!currentFieldDescribe.optionApiName.equals(targetFieldDescribe.optionApiName)){
                    currentOption = new ApiOption(childDescribe.getLabel(), childDescribe.getName());

                    currentRelationshipOption = new ManyToManyRelationOption(currentOption.optionLabel, currentOption.optionApiName);
                    currentRelationshipOption.junctionObjectOption = currentOption;
                    currentRelationshipOption.leftObjectOption = new ApiOption(leftObjectDescribe.getLabel(), leftObjectDescribe.getName());
                    currentRelationshipOption.rightObjectOption = new ApiOption(rightObjectDescribe.getLabel(), rightObjectDescribe.getName());

                    
                    currentRelationshipOption.leftObjectJunctionField = targetFieldDescribe;
                    currentRelationshipOption.rightObjectJunctionField = currentFieldDescribe;

                    results.add(currentRelationshipOption);
                }
            }
        }

        /*
        System.debug('\n\n\n\n\n\n\n');
        System.debug('expected keys');
        for (String potentialKey : potentialJunctionObjects.keySet()) {
            System.debug(potentialKey);
        }
        System.debug('found keys:');
        for (String potentialKey2 : foundChildObjects) {
            System.debug(potentialKey2);
        }
        */

        if (results.size() > 1){
            results.add(0,new ManyToManyRelationOption());
        }
        
        return results;
    }
    

    /**
     * List the children available for a specific record.
     **/
    @AuraEnabled
    public static ManyToManyChildrenList listChildren(Id recordId) {
        //-- start of code

        ManyToManyChildrenList results = null;

        //-- name of the SObject from the given id
        ManyToManyChildrenList result = null;

        Schema.DescribeSObjectResult recordObjectType = getObjectTypeFromId(recordId);
        String optionApiName = recordObjectType.getName();
        String optionLabel = recordObjectType.getLabel();
        ObjectMapping manyToManyRelationship;
        // System.debug('optionApiName:' + optionApiName);
        
        //-- @TODO: move to a separate function
        //-- which many to many relationship should we explore
        
        try {
            //-- assume only a single relationship for now...
            manyToManyRelationship = OBJECT_MAPS.get(optionApiName);
            manyToManyRelationship = orientObjectMapping(manyToManyRelationship, optionApiName);
        } catch(Exception err){
            throw new AuraHandledException('Unable to find ManyToManyRelationship definition for ' + optionLabel + '. Please contact your administrator');
        }

        //-- @INVARIANT - we have our relationships
        //-- and have those relationships oriented to the current record (as the source)
        // System.debug('manyToManyRelationship');System.debug(manyToManyRelationship);

        //-- @TODO: should we include multiples?
        //-- we cannot provide any arguments to the component
        //-- to specify which relationship we want.
        //-- so do we include a list of lists so they will all work?

        //-- @TODO: include try / catch
        //try {
        results = findManyToManyChildren(manyToManyRelationship, recordId);
        //} catch(Exception err){
        // //-- message already captured from below so use that
        // throw new AuraHandledException(err.getMessage());
        //}
        
        //try {
        //} catch(Exception err){
        //    throw new AuraHandledException('Exception occurred when processing: ListManyToManyChildren');
        //}
        
        return(results);
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
    

    /** @TODO: move to a class / sobject */
    private class ObjectMapping {
        public String sourceObject;
        public String targetObject;
        public String junctionObject;

        public ObjectMapping(){}

        public ObjectMapping(String sourceObject, String targetObject, String junctionObject){
            this.sourceObject = sourceObject;
            this.targetObject = targetObject;
            this.junctionObject = junctionObject;
        }
    }

    /** Represents a list of children */
    public class ManyToManyChildrenList {
        @AuraEnabled
        public String childSObjectType;
        
        @AuraEnabled
        public String childSObjectLabel;

        @AuraEnabled
        public Id[] childrenList;

        public ManyToManyChildrenList(){
            this.childrenList = new Id[]{};
        }
    }

    ///** Represents a many-to-many child (from a record's viewpoint) */
    //public class ManyToManyChildRecord {
    //    /** Represents the Id of the child record */
    //    @AuraEnabled
    //    public String recordId;
    //
    //    /** The SObject (API) type of the child SObject */
    //    @AuraEnabled
    //    public String sObjectName;
    //}

    public static Schema.DescribeSObjectResult getObjectTypeFromId(Id recordId){
        Schema.SObjectType objectType = recordId.getSObjectType();
        return objectType.getDescribe();
    }

    /**
     * Determines if we are on the other side of the Many to Many relationship.
     * @param manyToManyRelationship ObjectMapping
     * @param sObjectName String
     * @return ObjectMapping - if the sObjectName is the target, then flips the relationship (source <-> target)
     */
    public static ObjectMapping orientObjectMapping(ObjectMapping manyToManyRelationship, String sObjectName){
        ObjectMapping results;

        if (manyToManyRelationship.sourceObject.equalsIgnoreCase(sObjectName)){
            //-- we are already oriented
            results = manyToManyRelationship;
        } else {
            results = new ObjectMapping();
            results.sourceObject = manyToManyRelationship.targetObject;
            results.targetObject = manyToManyRelationship.sourceObject;
            results.junctionObject = manyToManyRelationship.junctionObject;
        }

        return results;
    }

    /**
     * Get a list of Many to Many Children for a given Many to Many relationship
     * for a particular record.
     * @param manyToManyRelationship (ObjectMapping) - a description of a many to many relationship.
     * @param recordId (Id)
     * @return ManyToManyChildrenList - collection of the child records from the perspective of recordId of a given Many to Many relationship.
     **/
    public static ManyToManyChildrenList findManyToManyChildren(ObjectMapping manyToManyRelationship, Id recordId){
        ManyToManyChildrenList results = null;

        String optionApiName = manyToManyRelationship.sourceObject;

        //-- get a describe for each of the types of objects.
        Schema.DescribeSObjectResult sourceObjectDescribe = getSObjectDescription(manyToManyRelationship.sourceObject);
        Schema.DescribeSObjectResult targetObjectDescribe = getSObjectDescription(manyToManyRelationship.targetObject);
        //Schema.DescribeSObjectResult junctionObjectDescribe = getSObjectDescription(manyToManyRelationship.junctionObject);

        //Schema.ChildRelationship targetRelationship = getChildRelationshipFor(junctionObjectDescribe, manyToManyRelationship.junctionObject);
        Schema.ChildRelationship targetRelationship = getChildRelationshipFor(targetObjectDescribe, manyToManyRelationship.junctionObject);
        Schema.ChildRelationship sourceRelationship = getChildRelationshipFor(sourceObjectDescribe, manyToManyRelationship.junctionObject);

        String targetRelationshipField = String.valueOf(targetRelationship.getField());
        String sourceRelationshipField = String.valueOf(sourceRelationship.getField());

        //-- @INVARIANT - we know the fields used to provide the relationship
        // System.debug('Field used to join source to the junction object:' + sourceRelationshipField);
        // System.debug('Field used to join target to the junction object:' + targetRelationshipField);

        String expectedSOQL = String.format(LIST_CHILDREN_QUERY,
            new String[]{targetRelationshipField, manyToManyRelationship.junctionObject, sourceRelationshipField}
        );

        // System.debug('SOQL to run:' + expectedSOQL);
        //-- for example: SELECT Id, ContactId__c FROM ltng_M2M_AccountContactRelationship__c WHERE AccountId__c = :recordId

        SObject[] farChildren = Database.query(expectedSOQL);
        
        //-- @INVARIANT - we have the list of all the children record ids
        //-- from the far side of the many to many relationship
        // System.debug('farChildren'); System.debug(farChildren);

        results = new ManyToManyChildrenList();
        results.childSObjectType = targetObjectDescribe.getName();
        results.childSObjectLabel = targetObjectDescribe.getLabel();

        String farRelationshipRecordId;
        for(SObject farChildRelationship : farChildren){
            farRelationshipRecordId = String.valueOf(farChildRelationship.get(targetRelationshipField));
            results.childrenList.add(farRelationshipRecordId);
        }

        //-- @INVARIANT - we know information about the far side of the many to many relationship
        //-- this includes the name of the object and label of the object on the far side
        //-- and the list of children from this record's perspective
        // System.debug('results'); System.debug(results);

        return(results);
    }

    public static Schema.DescribeSObjectResult getSobjectDescription(String sObjectName){
        Schema.DescribeSObjectResult[] resultList = Schema.describeSObjects(new String[]{sObjectName});
        return resultList[0];
    }

    public static Schema.ChildRelationship getChildRelationshipFor(Schema.DescribeSObjectResult sobjectDescribe, String targetSobject){
        Schema.ChildRelationship result;
        String childRelationSObject;
        for( Schema.ChildRelationship childRelation : sobjectDescribe.getChildRelationships() ){
            childRelationSObject = String.valueOf(childRelation.getChildSObject());
            if (childRelationSObject.equals(targetSObject)){
                result = childRelation;
            }
        }
        return result;
    }
}