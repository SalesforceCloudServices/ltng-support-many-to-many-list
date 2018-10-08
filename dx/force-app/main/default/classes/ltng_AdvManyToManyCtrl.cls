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

}