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