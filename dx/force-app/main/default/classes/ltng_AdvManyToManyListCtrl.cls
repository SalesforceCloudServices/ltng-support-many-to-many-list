/**
 * Controller for the component to list the many far children
 * in a many to many relationship.
 * 
 * @class - ltng_AdvManyToManyListCtrl
 **/
public with sharing class ltng_AdvManyToManyListCtrl {

    /** Templated query for finding children of a related record */
    public static final String LIST_CHILDREN_QUERY = 'SELECT Id, {0} FROM {1} WHERE {2} = :recordId';

    /** Standard SObject Id field */
    public static final String ID_FIELD = 'Id';

    public static final String LAYOUT_TYPE_BLANK = '';
    public static final String LAYOUT_TYPE_COMPACT = 'Compact';

    public static final String FIELD_DELIMITER = ';';

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
        Schema.DescribeSObjectResult recordObjectType = ltng_AdvManyToManyUtil.getSObjectDescription(recordId);
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
        Schema.DescribeSObjectResult recordObjectType = ltng_AdvManyToManyUtil.getSObjectDescription(recordId);
        String objectApiName = recordObjectType.getName();
        String objectLabel = recordObjectType.getLabel();
        ltng_M2M_Relationship__c[] manyToManyRelationships;
        ltng_M2M_Relationship__c manyToManyRelationship;
        
        if (relationshipId != null) {
            manyToManyRelationship = [
                SELECT Id, Name, JunctionObjectAPIName__c,
                    LeftObjectAPIName__c, JunctionLeftObjectRelationshipField__c,
                    RightObjectAPIName__c, JunctionRightObjectRelationshipField__c,
                    JunctionObjectUsesCompactLayout__c, JunctionObjectSpecificFields__c,
                    LeftObjectUsesCompactLayout__c, LeftObjectSpecificFields__c,
                    RightObjectUsesCompactLayout__c, RightObjectSpecificFields__c
                FROM ltng_M2M_Relationship__c
                WHERE Id = :relationshipId
            ];
        } else {
            manyToManyRelationship = [
                SELECT Id, Name, JunctionObjectAPIName__c,
                    LeftObjectAPIName__c, JunctionLeftObjectRelationshipField__c,
                    RightObjectAPIName__c, JunctionRightObjectRelationshipField__c,
                    JunctionObjectUsesCompactLayout__c, JunctionObjectSpecificFields__c,
                    LeftObjectUsesCompactLayout__c, LeftObjectSpecificFields__c,
                    RightObjectUsesCompactLayout__c, RightObjectSpecificFields__c
                FROM ltng_M2M_Relationship__c
                WHERE (LeftObjectAPIName__c = :objectApiName OR RightObjectAPIName__c = :objectApiName)
            ];
        }

        manyToManyRelationship = ltng_AdvManyToManyUtil.orientRelationship(manyToManyRelationship, objectApiName);

        results = determineFarChildList(manyToManyRelationship, recordId);

        return(results);
    }

    private static FarChildrenList determineFarChildList(ltng_M2M_Relationship__c manyToManyRelationship, Id recordId
    ){
        FarChildrenList results = null;

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

        Schema.DescribeSObjectResult targetObjectDescribe = ltng_AdvManyToManyUtil.getSObjectDescription(manyToManyRelationship.RightObjectAPIName__c);
        Schema.DescribeSObjectResult junctionObjectDescribe = ltng_AdvManyToManyUtil.getSObjectDescription(manyToManyRelationship.JunctionObjectAPIName__c);

        results = new FarChildrenList();
        results.childSObjectType = targetObjectDescribe.getName();
        results.childSObjectLabel = targetObjectDescribe.getLabel();

        results.junctionSObjectType = junctionObjectDescribe.getName();
        results.junctionSObjectLabel = junctionObjectDescribe.getLabel();

        results.leftObjectUsesCompactLayout = manyToManyRelationship.LeftObjectUsesCompactLayout__c;
        results.leftObjectSpecificFields = manyToManyRelationship.LeftObjectSpecificFields__c;
        results.junctionObjectUsesCompactLayout = manyToManyRelationship.JunctionObjectUsesCompactLayout__c;
        results.junctionObjectSpecificFields = manyToManyRelationship.JunctionObjectSpecificFields__c;
        results.rightObjectUsesCompactLayout = manyToManyRelationship.RightObjectUsesCompactLayout__c;
        results.rightObjectSpecificFields = manyToManyRelationship.RightObjectSpecificFields__c;

        results.leftLayoutType = results.leftObjectUsesCompactLayout ? LAYOUT_TYPE_COMPACT : LAYOUT_TYPE_BLANK;
        results.junctionLayoutType = results.junctionObjectUsesCompactLayout ? LAYOUT_TYPE_COMPACT : LAYOUT_TYPE_BLANK;
        results.rightLayoutType = results.rightObjectUsesCompactLayout ? LAYOUT_TYPE_COMPACT : LAYOUT_TYPE_BLANK;

        results.leftObjectFields = splitObjectFields(manyToManyRelationship.LeftObjectSpecificFields__c);
        results.junctionObjectFields = splitObjectFields(manyToManyRelationship.JunctionObjectSpecificFields__c);
        results.rightObjectFields = splitObjectFields(manyToManyRelationship.RightObjectSpecificFields__c);

        results.showLeftObject = results.leftObjectUsesCompactLayout || !String.isEmpty(manyToManyRelationship.LeftObjectSpecificFields__c);
        results.showJunctionObject = results.junctionObjectUsesCompactLayout || !String.isEmpty(manyToManyRelationship.JunctionObjectSpecificFields__c);
        results.showRightObject = results.rightObjectUsesCompactLayout || !String.isEmpty(manyToManyRelationship.RightObjectSpecificFields__c);

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

    public static String[] splitObjectFields(String objectFieldList) {
        String[] results = null;

        if (!String.isEmpty(objectFieldList)) {
            results = objectFieldList.split(FIELD_DELIMITER);
        }

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

        @AuraEnabled
        public String leftLayoutType;
        @AuraEnabled
        public String rightLayoutType;
        @AuraEnabled
        public String junctionLayoutType;

        @AuraEnabled
        public String[] leftObjectFields;
        @AuraEnabled
        public String[] rightObjectFields;
        @AuraEnabled
        public String[] junctionObjectFields;

        @AuraEnabled
        public Boolean leftObjectUsesCompactLayout;
        @AuraEnabled
        public Boolean rightObjectUsesCompactLayout;
        @AuraEnabled
        public Boolean junctionObjectUsesCompactLayout;

        @AuraEnabled
        public String leftObjectSpecificFields;
        @AuraEnabled
        public String rightObjectSpecificFields;
        @AuraEnabled
        public String junctionObjectSpecificFields;

        @AuraEnabled
        public Boolean showLeftObject;
        @AuraEnabled
        public Boolean showRightObject;
        @AuraEnabled
        public Boolean showJunctionObject;

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
}