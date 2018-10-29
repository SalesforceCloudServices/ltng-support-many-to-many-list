/**
 * Utility class for dealing with Many to Many Relationships.
 * @class ltng_AdvManyToManyUtil
 **/
public with sharing class ltng_AdvManyToManyUtil {
    
    /** represents no selection **/
    public static final String NO_SELECTION = '-No Selection-';
    public static final String NO_SELECTION_VALUE = '';

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Methods for describing Relationships and Objects
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
            results = flipRelationship(relationship);
        }

        return results;
    }

    /**
     * Determines if the same object is used on both the left and right of the relationship.
     * <p>It is a many to many relationship on the same object</p>
     * @param relationship (ltng_M2M_Relationship__c)
     * @return (Boolean)
     */
    public static Boolean isReflectiveRelationship(ltng_M2M_Relationship__c relationship){
        Boolean results = false;

        if (relationship != null) {
            if (relationship.LeftObjectAPIName__c == relationship.RightObjectAPIName__c) {
                results = true;
            } else {
                results = (
                    relationship.LeftObjectApiName__c != null &&
                    relationship.LeftObjectAPIName__c.equals(relationship.RightObjectAPIName__c)
                );
            }
        }

        return results;
    }

    /**
     * Flips the relationship between the left and right sides.
     * <p>Thinking about a many to many relationship, we have Opportunities and Products
     * with OpportunityProducts as the junction object.</p>
     * <p>Whether Opportunities is considered the 'left' or the 'right'
     *  - doesn't make much difference. So this method allows for swapping them</p>
     * @param relationship (ltng_M2M_Relationship__c) - a Many to Many Relationship to be switched.
     * @return ltng_M2M_Relationship__c - the flipped relation.
     **/
    public static ltng_M2M_Relationship__c flipRelationship(ltng_M2M_Relationship__c relationship){
        ltng_M2M_Relationship__c relationshipClone;

        relationshipClone = relationship.clone(false, false, false, false);
        System.debug('relationshipClone'); System.debug(relationshipClone);

        relationship.LeftObjectAPIName__c = relationshipClone.RightObjectAPIName__c;
        relationship.JunctionLeftObjectRelationshipField__c = relationshipClone.JunctionRightObjectRelationshipField__c;
        relationship.LeftObjectUsesCompactLayout__c = relationshipClone.RightObjectUsesCompactLayout__c;
        relationship.LeftObjectSpecificFields__c = relationshipClone.RightObjectSpecificFields__c;

        relationship.RightObjectAPIName__c = relationshipClone.LeftObjectAPIName__c;
        relationship.JunctionRightObjectRelationshipField__c = relationshipClone.JunctionLeftObjectRelationshipField__c;
        relationship.RightObjectUsesCompactLayout__c = relationshipClone.LeftObjectUsesCompactLayout__c;
        relationship.RightObjectSpecificFields__c = relationshipClone.LeftObjectSpecificFields__c;

        return relationship;
    }

    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //-- Internal Classes used for communication
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -

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
}