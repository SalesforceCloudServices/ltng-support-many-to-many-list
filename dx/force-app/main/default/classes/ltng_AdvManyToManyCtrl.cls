/**
 * Controller for managing many to many relationships.
 * @class ltng_ManyToManyCtrl
 ltng_AdvManyToManyCtrl
 **/
public with sharing class ltng_AdvManyToManyCtrl {

    /** represents no selection **/
    public static final String NO_SELECTION = '-No Selection-';
    public static final String NO_SELECTION_VALUE = '';

    /** Templated query for finding children of a related record */
    public static final String LIST_CHILDREN_QUERY = 'SELECT Id, {0} FROM {1} WHERE {2} = :recordId';

    /** Standard SObject Id field */
    public static final String ID_FIELD = 'Id';

    //-- errors to show
    //-- @TODO: move to custom setting

    /** represents the error if the user is unable to get a list of sObjects */
    public static final String ERROR_CANNOT_LIST_SOBJECTS = 'Unable to access list of SObjects. Please contact your administrator';

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Methods for Retrieving Children
    //-- @TODO: separate to separate class
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

    /**
     * Provide the list of Relationships that would apply here (for the drop down)
     * @param recordId (Id)
     * @return ltng_M2M_Relationship__c[] - list of the available relationships.
     **/
    @AuraEnabled
    public static ltng_M2M_Relationship__c[] listAvailableRelationships(Id recordId) {
        ltng_M2M_Relationship__c[] results;

        if (recordId == null) {
            return results;
        }

        //-- name of the SObject from the given id
        Schema.DescribeSObjectResult recordObjectType = getSObjectDescription(recordId);
        String objectApiName = recordObjectType.getName();
        String objectLabel = recordObjectType.getLabel();
        
        try {
            results = [
                SELECT Id, Name
                FROM ltng_M2M_Relationship__c
                WHERE LeftObjectAPIName__c = :objectApiName OR RightObjectAPIName__c = :objectApiName
            ];
        } catch(Exception err){
            throw new AuraHandledException('Exception occurred when processing: listAvailableRelationships');
        }
        
        return(results);
    }

    /**
     * List the children available for a specific record.
     **/
    @AuraEnabled
    public static FarChildrenList listChildren(Id recordId, Id relationshipId) {
        //-- start of code
        FarChildrenList results = null;

        if (recordId == null) {
            return results;
        }

        //-- name of the SObject from the given id
        Schema.DescribeSObjectResult recordObjectType = getSObjectDescription(recordId);
        String objectApiName = recordObjectType.getName();
        String objectLabel = recordObjectType.getLabel();
        ltng_M2M_Relationship__c[] manyToManyRelationships;
        ltng_M2M_Relationship__c manyToManyRelationship;
        System.debug('objectApiName:' + objectApiName);
        
        manyToManyRelationship = [
            SELECT Id, Name, JunctionObjectAPIName__c,
                LeftObjectAPIName__c, JunctionLeftObjectRelationshipField__c,
                RightObjectAPIName__c, JunctionRightObjectRelationshipField__c
            FROM ltng_M2M_Relationship__c
            WHERE Id = :relationshipId OR
                (LeftObjectAPIName__c = :objectApiName OR RightObjectAPIName__c = :objectApiName)
            LIMIT 1
        ];

        manyToManyRelationship = orientRelationship(manyToManyRelationship, objectApiName);

        String targetRelationshipField = manyToManyRelationship.JunctionRightObjectRelationshipField__c;
        String sourceRelationshipField = manyToManyRelationship.JunctionLeftObjectRelationshipField__c;
        String junctionObjectApiName = manyToManyRelationship.JunctionObjectAPIName__c;

        String expectedSOQL = String.format(LIST_CHILDREN_QUERY,
            new String[]{targetRelationshipField, junctionObjectApiName, sourceRelationshipField}
        );

        //System.debug('SOQL to run:' + expectedSOQL);
        //-- for example: SELECT Id, ContactId__c FROM ltng_M2M_AccountContactRelationship__c WHERE AccountId__c = :recordId
        
        //-- @INVARIANT - we have the list of all the children record ids
        //-- from the far side of the many to many relationship
        // System.debug('farChildren'); System.debug(farChildren);

        Schema.DescribeSObjectResult targetObjectDescribe = getSObjectDescription(manyToManyRelationship.RightObjectAPIName__c);
        Schema.DescribeSObjectResult junctionObjectDescribe = getSObjectDescription(manyToManyRelationship.JunctionObjectAPIName__c);

        results = new FarChildrenList();
        results.childSObjectType = targetObjectDescribe.getName();
        results.childSObjectLabel = targetObjectDescribe.getLabel();

        results.junctionSObjectType = junctionObjectDescribe.getName();
        results.junctionSObjectLabel = junctionObjectDescribe.getLabel();

        SObject[] farChildren = Database.query(expectedSOQL);

        String farRelationshipRecordId;
        ChildEntry entry;
        for(SObject farChildRelationship : farChildren){
            entry = new ChildEntry();
            entry.childId = String.valueOf(farChildRelationship.get(targetRelationshipField));
            entry.junctionId = String.valueOf(farChildRelationship.get(ID_FIELD));
            results.childrenList.add(entry);
        }

        //-- @INVARIANT - we know information about the far side of the many to many relationship
        //-- this includes the name of the object and label of the object on the far side
        //-- and the list of children from this record's perspective
        // System.debug('results'); System.debug(results);

        return(results);
    }

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Methods for updating many to many relationships
    //-- @TODO: separate to separate class
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

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

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Internal Classes used for communication
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

    /**
     * Represents a collection of specific children records
     * to be displayed out in a Far Child list.
     * <p>Used when asking to list children,
     * and not for editing relationships</p>
     **/
    public class FarChildrenList {
        @AuraEnabled
        public String childSObjectType;
        
        @AuraEnabled
        public String childSObjectLabel;

        @AuraEnabled
        public String junctionSObjectType;
        
        @AuraEnabled
        public String junctionSObjectLabel;

        @AuraEnabled
        public ChildEntry[] childrenList;

        public FarChildrenList(){
            this.childrenList = new ChildEntry[]{};
        }
    }

    /**
     * Represents a specific Far Child object.
     * <p>Includes the link to the child record,
     * but also the junction/intermediary used to get there.</p>
     */
    public class ChildEntry {
        @AuraEnabled
        public String childId;

        @AuraEnabled
        public String junctionId;
    }

    /**
     * Represents an Api entity - with a name and an API identifier.
     * <p>Used by the Relation Editor when showing Objects and fields
     * available for selection</p>
     */
    public virtual class ApiOption {
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

    /**
     * Represents an SObject option
     **/
    public class SObjectApiOption extends ApiOption {
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
    public class ManyToManyRelationOption extends ApiOption {
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

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Internal Classes used for communication
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

    /**
     * Given a record id, determines the SObject Describe of the record.
     * @param recordId (Id)
     * @return Schema.DescribeSObjectResult
     */
    public static Schema.DescribeSObjectResult getSObjectDescription(Id recordId){
        Schema.SObjectType objectType = recordId.getSObjectType();
        return objectType.getDescribe();
    }

    /**
     * Given an SObject Name, return the Describe of that SObject
     * @param sObjectName (String)
     * @return Schema.DescribeSObjectResult
     **/
    public static Schema.DescribeSObjectResult getSobjectDescription(String sObjectName){
        Schema.DescribeSObjectResult[] resultList = Schema.describeSObjects(new String[]{sObjectName});
        return resultList[0];
    }

    /**
     * Orients a relationship so on a many to many relationship,
     * a given SObject type is on the left.
     * @param relationship (ltng_M2M_Relationship__c) - a Many to Many Relationship (with an object on a left, right and junction between)
     * @param sObjectApiName (String) - the object we want on the left of the relationship
     * @return updated relationship
      */
    public static ltng_M2M_Relationship__c orientRelationship(ltng_M2M_Relationship__c relationship, String sObjectApiName){
        ltng_M2M_Relationship__c results;
        ltng_M2M_Relationship__c relationshipClone;

        if (relationship.LeftObjectAPIName__c.equalsIgnoreCase(sObjectApiName)) {
            results = relationship;
        } else {
            System.debug('relationship is out of alignment');
            relationshipClone = relationship.clone(false, false, false, false);
            System.debug('relationshipClone'); System.debug(relationshipClone);

            relationship.LeftObjectAPIName__c = relationshipClone.RightObjectAPIName__c;
            relationship.JunctionLeftObjectRelationshipField__c = relationshipClone.JunctionRightObjectRelationshipField__c;

            relationship.RightObjectAPIName__c = relationshipClone.LeftObjectAPIName__c;
            relationship.JunctionRightObjectRelationshipField__c = relationshipClone.JunctionLeftObjectRelationshipField__c;
            results = relationship;
        }

        return results;
    }
}