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

    public class ManyToManyChildrenList {
        @AuraEnabled
        public String childSObjectType;

        @AuraEnabled
        public Id[] childrenList;

        public ManyToManyChildrenList(){
            this.childrenList = new Id[]{};
            this.childSObjectType = null;
        }
    }

    /**
     * Description for method
     **/
    @AuraEnabled
    public static ManyToManyChildRecord[] listChildren(Id recordId) {
        //-- start of code

        ManyToManyChildRecord[] results = new ManyToManyChildRecord[]{};

        //-- name of the SObject from the given id
        String sObjectTypeName = getObjectTypeFromId(recordId);
        // System.debug('sObjectTypeName:' + sObjectTypeName);
        
        //-- @TODO: move to a separate function
        //-- which many to many relationship should we explore
        ObjectMapping objectRelation = OBJECT_MAPS.get(sObjectTypeName);
        // System.debug('objectRelation');System.debug(objectRelation);

        /*
        String[] objectsToInvestigate = new String[]{
            objectRelation.sourceObject,
            objectRelation.targetObject,
            objectRelation.junctionObject
        };
        */

        results.addAll(
            findManyToManyChildren(objectRelation, recordId)
        );

        /*
        SObject[] expectedResults = [
            SELECT Id, ContactId__c
            FROM ltng_M2M_AccountContactRelationship__c
            WHERE AccountId__c = :recordId
        ];
        */
        
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

    /** Represents a many-to-many child (from a record's viewpoint) */
    public class ManyToManyChildRecord {
        /** Represents the Id of the child record */
        @AuraEnabled
        public String recordId;

        /** The SObject (API) type of the child SObject */
        @AuraEnabled
        public String sObjectName;
    }

    public static String getObjectTypeFromId(Id recordId){
        Schema.SObjectType objectType = recordId.getSObjectType();
        String result = String.valueOf(objectType);
        return result;
    }

    /**
     * Determines if we are on the other side of the Many to Many relationship.
     * @param objectRelation ObjectMapping
     * @param sObjectName String
     * @return ObjectMapping - if the sObjectName is the target, then flips the relationship (source <-> target)
     */
    public static ObjectMapping orientObjectMapping(ObjectMapping objectRelation, String sObjectName){
        ObjectMapping results;

        if (objectRelation.sourceObject.equalsIgnoreCase(sObjectName)){
            //-- we are already oriented
            results = objectRelation;
        } else {
            results = new ObjectMapping();
            results.sourceObject = objectRelation.targetObject;
            results.targetObject = objectRelation.sourceObject;
            results.junctionObject = objectRelation.junctionObject;
        }

        return results;
    }

    /**
     * Get a list of Many to Many Children for a given Many to Many relationship
     * for a particular record.
     * @param objectRelation (ObjectMapping) - a description of a many to many relationship.
     * @param recordId (Id)
     * @return ManyToManyChildRecord[] - collection of the child records from the perspective of recordId of a given Many to Many relationship.
     **/
    public static ManyToManyChildRecord[] findManyToManyChildren(ObjectMapping objectRelation, Id recordId){
        ManyToManyChildRecord[] results = new ManyToManyChildRecord[]{};

        String sObjectTypeName = objectRelation.sourceObject;

        //-- get a describe for each of the types of objects.
        Schema.DescribeSObjectResult sourceObjectDescribe = getSObjectDescription(objectRelation.sourceObject);
        Schema.DescribeSObjectResult targetObjectDescribe = getSObjectDescription(objectRelation.targetObject);
        Schema.DescribeSObjectResult junctionObjectDescribe = getSObjectDescription(objectRelation.junctionObject);

        //Schema.ChildRelationship targetRelationship = getChildRelationshipFor(junctionObjectDescribe, objectRelation.junctionObject);
        Schema.ChildRelationship targetRelationship = getChildRelationshipFor(targetObjectDescribe, objectRelation.junctionObject);
        System.debug('targetRelationship:');System.debug(targetRelationship);

        Schema.ChildRelationship sourceRelationship = getChildRelationshipFor(sourceObjectDescribe, objectRelation.junctionObject);
        System.debug('sourceRelationship:');System.debug(sourceRelationship);

        String targetRelationshipField = String.valueOf(targetRelationship.getField());
        String sourceRelationshipField = String.valueOf(sourceRelationship.getField());

        String expectedSOQL = String.format(LIST_CHILDREN_QUERY,
            new String[]{targetRelationshipField, objectRelation.junctionObject, sourceRelationshipField}
        );
        System.debug('SOQL to run:' + expectedSOQL);
        //-- for example: SELECT Id, ContactId__c FROM ltng_M2M_AccountContactRelationship__c WHERE AccountId__c = :recordId

        SObject[] farChildren = Database.query(expectedSOQL);
        System.debug('farChildren'); System.debug(farChildren);

        String farRelationshipId;
        ManyToManyChildRecord childRecord;
        for(SObject farChildRelationship : farChildren){
            farRelationshipId = String.valueOf(farChildRelationship.get(targetRelationshipField));
            childRecord = new ManyToManyChildRecord();
            childRecord.recordId = farRelationshipId;
            childRecord.sObjectName = objectRelation.targetObject;
            results.add(childRecord);
        }

        System.debug('results'); System.debug(results);

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
            System.debug('childRelationSObject:' + childRelationSObject);
            if (childRelationSObject.equals(targetSObject)){
                result = childRelation;
            }
        }
        return result;
    }
}