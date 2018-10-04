/**
 * Controller for the ltng_ManyToManyList component.
 * @class ltng_ManyToManyListCtrl
 **/
public with sharing class ltng_ManyToManyListCtrl {

    /** Templated query for finding children of a related record */
    public static final String LIST_CHILDREN_QUERY = 'SELECT Id, {0} FROM {1} WHERE {2} = :recordId';

    public static final Map<String,ObjectMapping> OBJECT_MAPS = getObjectMaps();

    private static Map<String,ObjectMapping> getObjectMaps(){
        //-- @TODO: reduce to a single entry and allow for flipping
        Map<String,ObjectMapping> result = new Map<String,ObjectMapping>();
        result.put('ltng_M2M_Account__c', new ObjectMapping('ltng_M2M_Account__c', 'ltng_M2M_Contact__c', 'ltng_M2M_AccountContactRelationship__c'));
        result.put('ltng_M2M_Contact__c', new ObjectMapping('ltng_M2M_Contact__c', 'ltng_M2M_Account__c', 'ltng_M2M_AccountContactRelationship__c'));
        return result;
    }

    /**
     * Description for method
     **/
    @AuraEnabled
    public static ManyToManyChildrenList listChildren(Id recordId) {
        //-- start of code

        ManyToManyChildrenList results = null;

        //-- name of the SObject from the given id
        ManyToManyChildrenList result = null;

        Schema.DescribeSObjectResult recordObjectType = getObjectTypeFromId(recordId);
        String sObjectApiName = recordObjectType.getName();
        String sObjectLabel = recordObjectType.getLabel();
        ObjectMapping manyToManyRelationship;
        // System.debug('sObjectApiName:' + sObjectApiName);
        
        //-- @TODO: move to a separate function
        //-- which many to many relationship should we explore
        
        try {
            //-- assume only a single relationship for now...
            manyToManyRelationship = OBJECT_MAPS.get(sObjectApiName);
            manyToManyRelationship = orientObjectMapping(manyToManyRelationship, sObjectApiName);
        } catch(Exception err){
            throw new AuraHandledException('Unable to find ManyToManyRelationship definition for ' + sObjectLabel + '. Please contact your administrator');
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

        String sObjectApiName = manyToManyRelationship.sourceObject;

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