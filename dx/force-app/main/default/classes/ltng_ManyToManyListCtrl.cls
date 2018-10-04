/**
 * Controller for the ltng_ManyToManyList component.
 * @class ltng_ManyToManyListCtrl
 **/
public with sharing class ltng_ManyToManyListCtrl {

    public static final String LIST_CHILDREN_QUERY = 'SELECT Id, {0} FROM {1} WHERE {2} = :recordId';

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
    public static ManyToManyChildrenList listChildren(Id recordId) {
        ManyToManyChildrenList results = new ManyToManyChildrenList();

        Map<String,ObjectMapping> objectMaps = new Map<String,ObjectMapping>();
        objectMaps.put('ltng_M2M_Account__c', new ObjectMapping('ltng_M2M_Account__c', 'ltng_M2M_Contact__c', 'ltng_M2M_AccountContactRelationship__c'));
        objectMaps.put('ltng_M2M_Contact__c', new ObjectMapping('ltng_M2M_Contact__c', 'ltng_M2M_Account__c', 'ltng_M2M_AccountContactRelationship__c'));

        String sObjectTypeName = getObjectTypeFromId(recordId);
        System.debug('sObjectTypeName:' + sObjectTypeName);

        ObjectMapping objectRelation = objectMaps.get(sObjectTypeName);
        System.debug('objectRelation');System.debug(objectRelation);

        String[] objectsToInvestigate = new String[]{
            objectRelation.sourceObject,
            objectRelation.targetObject,
            objectRelation.junctionObject
        };

        results.childSObjectType = objectRelation.targetObject;

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

        SObject[] farChildren = Database.query(expectedSOQL);
        System.debug('farChildren'); System.debug(farChildren);

        String farRelationshipId;
        for(SObject farChildRelationship : farChildren){
            farRelationshipId = String.valueOf(farChildRelationship.get(targetRelationshipField));
            results.childrenList.add(farRelationshipId);
        }

        System.debug('results'); System.debug(results);

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

    private class ObjectMapping {
        public String sourceObject;
        public String targetObject;
        public String junctionObject;

        public ObjectMapping(String sourceObject, String targetObject, String junctionObject){
            this.sourceObject = sourceObject;
            this.targetObject = targetObject;
            this.junctionObject = junctionObject;
        }
    }

    public static String getObjectTypeFromId(Id recordId){
        Schema.SObjectType objectType = recordId.getSObjectType();
        String result = String.valueOf(objectType);
        return result;
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