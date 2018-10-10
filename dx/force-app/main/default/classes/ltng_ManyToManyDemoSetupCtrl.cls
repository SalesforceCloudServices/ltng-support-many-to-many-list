/**
 * Controller for the Demo Setup page.
 **/
/*
 * //-- CHANGE
 * //-- ensure the class name matches the name of the Setup page + CTRL
 * //-- ex: ltng_ManyToManyDemoSetupCtrl
 **/
global with sharing class ltng_ManyToManyDemoSetupCtrl {

    //-- static
    
    /** URL patterm for navigating to a permissionSet **/
    global static final String DEFAULT_MISSING_PERMISSION_URL = '/one/one.app#/setup/PermSets/home';
	
	//--	-	-	-	-	-	-	-	-	-	-	-
	//-- START OF LINES TO UPDATE
	//--	-	-	-	-	-	-	-	-	-	-	-
	
	//-- set the values that specific to your project
	
    //-- The Name of your Permission Set
    //--	(e.g.: SELECT Id, Name FROM PermissionSet WHERE Name = 'ManyToManyDemoParticipant')
    //--    ex: LightningSupportDemoParticipant
    //--	We should use Permission Sets for all Demos, instead of modifying Profiles.
    
    /** Developer Name for the Permission Set **/
    global static final String PERMISSION_SET_NAME = 'ManyToManyDemoParticipant';
    
    
    //-- @CHANGE: replace YOUR_SOBJECT_API_NAME with the SObject Durable Name
    //-- 	of the objects you will create - (if objects are created)
    //--    ex: MyCustomObject__c
    //--    (e.g.:  SELECT DeveloperName, DurableId FROM EntityDefinition WHERE DeveloperName = 'Object API Name')
        
    /**
     * API Name of the Object to create.
     *	(Although not required, it is fairly common to create objects in setup)
     **/
    global static final String ACCOUNT_SOBJECT_NAME  = 'ltng_M2M_Account__c';
    global static final String CONTACT_SOBJECT_NAME  = 'ltng_M2M_Contact__c';
    global static final String JUNCTION_SOBJECT_NAME  = 'ltng_M2M_AccountContactRelationship__c';
    global static final String RELATION_SOBJECT_NAME  = 'ltng_M2M_Relationship__c';
    
    //-- @CHANGE: replace YOUR_RECORD_TYPE_NAME with the RecordType Developer Name
    //--	of the objects you will create - (if objects / record types are used)
    //--	ex: 'Master'
    //--	(e.g: SELECT Id, DeveloperName, Name, SObjectType FROM RecordType WHERE SObjectType = 'YOUR_RECORD_TYPE_NAME'
	
    /** Developer Name of the record types to use when creating records
    	(Leave blank if no record types are used)
    **/
    global static final String RT_NAME = '';

    

    /**
     * Method called from the Lightning Component to either:
     * 		Determine the steps that will be run,
     *		Or to run the steps and learn the results from running them.
     * 
     * @return SetupStep[] - list of setup steps ran and the status for each.
     **/
    @AuraEnabled
    global static SetupStep[] runSetup(boolean getInfoOnly){
    	
    	//-- Each method that is called returns a SetupStep instance.
    	
    	//-- if getInfoOnly is `TRUE`, then nothing is executed,
    	//-- and we only get info about the step to be run.
    	
    	//-- if getInfoOnly is `FALSE`, then the step is executed
    	//-- and info about what was run, including results/errors/etc., are returned.
    	
        SetupStep[] results = new SetupStep[]{
            removeAllBaseRecords(getInfoOnly),
            createBaseRecords(getInfoOnly),
            addUserToPermissionSet(getInfoOnly)
            //-- @CHANGE: add in additional steps as desired
        };
        return results;
    }

    //-- actual steps to run

    /**
     * Remove any of the base records that are currently there.
     * @param getInfoOnly (Boolean) - whether to report what would be done (true) or run the step (false)
     **/
    global static SetupStep removeAllBaseRecords( boolean getInfoOnly){
        SetupStep step = new SetupStep( new Map<String,Object>{
            'title' => 'Remove any existing base objects'
        });

        if(getInfoOnly){
            return step;
        }
        
        //-- @CHANGE: implement how to delete all records
        //-- 	(the following is an example set of code)
        
        /*
        SObject[] recordsToDelete = null;
        try {
            recordsToDelete = [
                SELECT Id
                FROM YOUR_SOBJECT_API_NAME
            ];
            
            delete recordsToDelete;
        } catch(Exception err){
            step.errMsg = 'Error occurred while attempting to delete all base records';
            step.devErrMsg = err.getMessage();
            //-- do nothing for now.
            System.debug(step.errMsg);
        }
        */
        
        step.markCompleted();
        return(step);
    }

    /**
     * Create the base records.
     * @param getInfoOnly (Boolean) - whether to report what would be done (true) or run the step (false)
     **/
    global static SetupStep createBaseRecords( boolean getInfoOnly ){
        SetupStep step = new SetupStep( new Map<String,Object>{
            'title' => 'Create Base Objects',
            'descr' => 'Create the objects that the demos start from'
        });

        if(getInfoOnly){
            return step;
        }
        
        //-- determine the record type Names => Salesforce ID translation map
		Set<String> RECORD_TYPE_NAMES = new Set<String>{RT_NAME};
        
        Map<String,Id> recordTypeMap = new Map<String,Id>();
        try {
        	if( !String.isEmpty(RT_NAME)){
				for( RecordType rt : [
					SELECT Id, DeveloperName, Name, SObjectType
					FROM RecordType
					WHERE SObjectType in :RECORD_TYPE_NAMES
				]){
					recordTypeMap.put(rt.DeveloperName, rt.Id);
				}
			}
        } catch(Exception err){
        	//-- for now, consume the error, as we handle it separately
        }
        
        //-- generate the objects to create by converting the Salesforce CLI:tree:export
        //-- into an apex version.
        
        /*
        It is recommended that you store all queries used for extracting data
        and store them separately from your data (in case you need it again)
        
        data/queries/YOUR_SOBJECT_API_NAME.txt
        SELECT Example_Value__c FROM YOUR_SOBJECT_API_NAME
        
        Say that the query you ran gave you this:
        sfdx force:data:tree:export -q queries/YOUR_SOBJECT_API_NAME.txt -d tree/
        
        { "records": [	{
							"attributes": {
								"type": "YOUR_SOBJECT_API_NAME"
							},
							"Example_Value__c": 1000
		}	]	}
		
		You can strip out the attributes, and only really care about:
		{ "Example_Value__c": 1000 }
		
		You can then convert it to an SObject like so:
		YOUR_SOBJECT_API_NAME[] baseRecords = new YOUR_SOBJECT_API_NAME[]{};
		
		baseRecords.add( new YOUR_SOBJECT_API_NAME(
			Example_Value__c = 1000
		));
		
		or
		
		baseRecords.add( new YOUR_SOBJECT_API_NAME(
			Example_Value__c = 1000,
			RecordTypeId = recordTypeMap.get(RT_NAME)
		));
		*/
		
		//-- @CHANGE: implement the records to be created
		//--	(the following is an example set of code)
		
        ltng_M2M_Account__c[] accountRecords = new ltng_M2M_Account__c[]{};
        ltng_M2M_Contact__c[] contactRecords = new ltng_M2M_Contact__c[]{};
        ltng_M2M_AccountContactRelationship__c[] junctionRecords = new ltng_M2M_AccountContactRelationship__c[]{};
        ltng_M2M_Relationship__c[] relationshipRecords = new ltng_M2M_Relationship__c[]{};
        
        accountRecords.add(new ltng_M2M_Account__c(
            AnnualRevenue__c = 600000000,
            BillingAddress__c = '3418 Poplar Ave\r\nShelby, TN 38111\r\nUSA',
            HasOptedOutOfEmail__c = false,
            Industry__c = 'Manufacturing',
            Name = 'Vand Enterprises, Inc.',
            NumberOfEmployees__c = 2000,
            Phone__c = '(674) 555-0153',
            ShippingAddress__c = '3418 Poplar Ave\r\nShelby, TN 38111\r\nUSA',
            Site__c = 'www.vandenterprise.com',
            Type__c = 'Customer',
            Website__c = 'www.vandenterprise.com'
        ));
        
        accountRecords.add(new ltng_M2M_Account__c(
            AnnualRevenue__c = 10000000,
            BillingAddress__c = '310 Henry St\r\nNew York, NY 10002\r\nUSA',
            HasOptedOutOfEmail__c = false,
            Industry__c = 'Communications',
            Name = 'Datanet, Inc. Main Branch',
            NumberOfEmployees__c = 400,
            Phone__c = '(678) 555-0153',
            Rating__c = 'Warm',
            ShippingAddress__c = '310 Henry St\r\nNew York, NY 10002\r\nUSA',
            Site__c = 'Main Branch',
            Type__c = 'Customer',
            Website__c = 'www.datamart.com'
        ));
        
        //-- Contacts
        
        contactRecords.add(new ltng_M2M_Contact__c(
            Department__c = 'Finance',
            DoNotCall__c = false,
            FirstName__c = 'Arthur',
            HasOptedOutOfEmail__c = false,
            HasOptedOutOfFax__c = false,
            LastName__c = 'Song',
            MailingAddress__c = '3418 Poplar Ave\r\nShelby, TN 38111\r\nUSA',
            Name = 'Mr. Arthur Song',
            Phone__c = '(772) 555-5429',
            Salutation__c = 'Mr.',
            Title__c = 'Financial Controller'
        ));
        
        contactRecords.add(new ltng_M2M_Contact__c(
            Department__c = 'Legal',
            DoNotCall__c = false,
            FirstName__c = 'Chris',
            HasOptedOutOfEmail__c = false,
            HasOptedOutOfFax__c = false,
            LastName__c = 'Friedman',
            MailingAddress__c = '3418 Poplar Ave\r\nShelby, TN 38111\r\nUSA',
            Name = 'Mr. Chris Friedman',
            Phone__c = '(227) 555-9079',
            Salutation__c = 'Mr.',
            Title__c = 'General Counsel'
        ));
        
        contactRecords.add(new ltng_M2M_Contact__c(
            Department__c = 'Legal',
            DoNotCall__c = false,
            FirstName__c = 'Billy',
            HasOptedOutOfEmail__c = false,
            HasOptedOutOfFax__c = false,
            LastName__c = 'Mack',
            MailingAddress__c = '310 Henry St\r\nNew York, NY 10002\r\nUSA',
            Name = 'Ms. Billy Mack',
            Phone__c = '(206) 555-4966',
            Salutation__c = 'Ms.',
            Title__c = 'General Counsel'
        ));
        
        contactRecords.add(new ltng_M2M_Contact__c(
            Department__c = 'Exec',
            DoNotCall__c = false,
            FirstName__c = 'Brenda',
            HasOptedOutOfEmail__c = false,
            HasOptedOutOfFax__c = false,
            LastName__c = 'McClure',
            MailingAddress__c = '3418 Poplar Ave\r\nShelby, TN 38111\r\nUSA',
            Name = 'Ms. Brenda McClure',
            Phone__c = '(415) 555-4922',
            Salutation__c = 'Ms.',
            Title__c = 'SVP of Strategy'
        ));
        
        contactRecords.add(new ltng_M2M_Contact__c(
            Department__c = 'Ops',
            DoNotCall__c = false,
            FirstName__c = 'Bill',
            HasOptedOutOfEmail__c = false,
            HasOptedOutOfFax__c = false,
            LastName__c = 'Martin',
            MailingAddress__c = '310 Henry St\r\nNew York, NY 10002\r\nUSA',
            Name = 'Mr. Bill Martin',
            Phone__c = '(673) 555-2802',
            Salutation__c = 'Mr.',
            Title__c = 'Operations Manager'
        ));
        
        contactRecords.add(new ltng_M2M_Contact__c(
            Department__c = 'Sales',
            DoNotCall__c = false,
            FirstName__c = 'Bree',
            HasOptedOutOfEmail__c = false,
            HasOptedOutOfFax__c = false,
            LastName__c = 'Reitz',
            MailingAddress__c = '2852 Bagley Circle\r\nSan Francisco, CA 94167\r\nUSA',
            Name = 'Ms. Bree Reitz',
            Phone__c = '(453) 555-6139',
            Salutation__c = 'Ms.',
            Title__c = 'Head of Partner Relations'
        ));
        
        //-- AccountContactRelation / Junction
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Influencer',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Influencer',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Influencer',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Decision Maker',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Decision Maker',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Influencer',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Business User;Decision Maker',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
        	EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Influencer',
			StartDate__c = null
        ));
        
        junctionRecords.add(new ltng_M2M_AccountContactRelationship__c(
			EndDate__c = null,
			IsActive__c = false,
			Roles__c = 'Executive Sponsor',
			StartDate__c = null
        ));
        
        //-- relationships
        
        relationshipRecords.add(new ltng_M2M_Relationship__c(
            JunctionLeftObjectRelationshipField__c = 'AccountId__c',
            JunctionObjectAPIName__c = 'ltng_M2M_AccountContactRelationship__c',
            JunctionRightObjectRelationshipField__c = 'ContactId__c',
            LeftObjectAPIName__c = 'ltng_M2M_Account__c',
            Name = 'Account Contacts',
            RightObjectAPIName__c = 'ltng_M2M_Contact__c'
        ));
        
        relationshipRecords.add(new ltng_M2M_Relationship__c(
            JunctionLeftObjectRelationshipField__c = 'ContactId__c',
            JunctionObjectAPIName__c = 'ltng_M2M_AccountContactRelationship__c',
            JunctionRightObjectRelationshipField__c = 'AccountId__c',
            LeftObjectAPIName__c = 'ltng_M2M_Contact__c',
            Name = 'Contact Accounts',
            RightObjectAPIName__c = 'ltng_M2M_Account__c'
        ));
        
        //-- finally add in the records
        
        try {
            insert accountRecords;
            //step.seeMore = baseRecords[0].Id;
        } catch( Exception err){
            step.errMsg = 'error occurred while creating example account records';
            step.devErrMsg = err.getMessage();
            System.debug(step.errMsg);
        }
        
        try {
            insert contactRecords;
            //step.seeMore = baseRecords[0].Id;
        } catch( Exception err){
            step.errMsg = 'error occurred while creating example contact records';
            step.devErrMsg = err.getMessage();
            System.debug(step.errMsg);
        }
        
        try {
            insert relationshipRecords;
            //step.seeMore = baseRecords[0].Id;
        } catch( Exception err){
            step.errMsg = 'error occurred while creating m2m relationship records';
            step.devErrMsg = err.getMessage();
            System.debug(step.errMsg);
        }
        
        //-- assign junction records
        
        junctionRecords[0].AccountId__c = accountRecords[0].Id; // vand
        junctionRecords[0].ContactId__c = contactRecords[3].Id; // brenda
        
        junctionRecords[1].AccountId__c = accountRecords[0].Id; // vand
        junctionRecords[1].ContactId__c = contactRecords[5].Id; // bree
        
        junctionRecords[2].AccountId__c = accountRecords[1].Id; // datanet
        junctionRecords[2].ContactId__c = contactRecords[2].Id; // billy mack
        
        junctionRecords[3].AccountId__c = accountRecords[0].Id; // vand
        junctionRecords[3].ContactId__c = contactRecords[3].Id; // brenda
        
        junctionRecords[4].AccountId__c = accountRecords[0].Id; // vand
        junctionRecords[4].ContactId__c = contactRecords[0].Id; // arthur
        
        junctionRecords[5].AccountId__c = accountRecords[0].Id; // vand
        junctionRecords[5].ContactId__c = contactRecords[1].Id; // friedman
        
        junctionRecords[6].AccountId__c = accountRecords[1].Id; // datanet
        junctionRecords[6].ContactId__c = contactRecords[4].Id; // martin
        
        junctionRecords[7].AccountId__c = accountRecords[1].Id; // datanet
        junctionRecords[7].ContactId__c = contactRecords[1].Id; // friedman
        
        junctionRecords[8].AccountId__c = accountRecords[1].Id; // datanet
        junctionRecords[8].ContactId__c = contactRecords[5].Id; // bree

        System.debug('junctionRecords');
        System.debug(junctionRecords);
        
        try {
            insert junctionRecords;
            //step.seeMore = baseRecords[0].Id;
        } catch( Exception err){
            step.errMsg = 'error occurred while creating base records';
            step.devErrMsg = err.getMessage();
            System.debug(step.errMsg);
        }

        step.markCompleted();
        return(step);
    }
    
    //-- @CHANGE: add in any additional steps
    /**
     * Example step
     * @param getInfoOnly (Boolean) - whether to report what would be done (true) or run the step (false)
     **/
    /*
    global static SetupStep doSomethingElse( boolean getInfoOnly ){
    	//-- @SEE SetupStep below - displayed in lightning component DemoSetupItem.cmp
    	SetupStep step = new SetupStep( new Map<String,Object>{
            'title' => 'Assign current user PermissionSet to see the Demo',
            'descr' => 'PermissionSet: ' + PERMISSION_SET_NAME + '. May take a second to take effect.',
            'reasoning' => 'All access is granted by PermissionSet. Only those with this PermissionSet can see the demo'
        });
    
        if( getInfoOnly ){
        	return(step);
        }
        
        //-- do stuff
        try {
        	//-- do stuff
        } catch(Exception err){
        	step.errMsg = 'Could not do stuff';
        	step.devErrMsg = err.getMessage();
        }
        
        step.markCompleted();
        return(step);
    }
    */
    
    
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    //--    END OF LINES TO UPDATE
    //--    -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -
    

    
    //--	-	-	-	-	-	-	-	-	-	-	-	-	-	-	-	-	-
    
    
    /**
     * Assign the user to the custom permission.
     * <p>Note: actual work must be a future to avoid a MixedDML issue</p>
     **/
    global static SetupStep addUserToPermissionSet( boolean getInfoOnly ){
        SetupStep step = new SetupStep( new Map<String,Object>{
            'title' => 'Assign current user PermissionSet to see the Demo',
            'descr' => 'PermissionSet: ' + PERMISSION_SET_NAME + '. May take a second to take effect.',
            'reasoning' => 'All access is granted by PermissionSet. Only those with this PermissionSet can see the demo'
        });

        if( getInfoOnly ){
            return(step);
        }

        addUserToPermissionSetImpl();

        step.markCompleted();
        return(step);
    }

    
    /**
     * Implementation that actually adds the user to the permission set.
     **/
    @future
    global static void addUserToPermissionSetImpl(){    
        Id userId = UserInfo.getUserId();
        PermissionSetAssignment[] results = null;
        
        try {
            PermissionSet ps = [
                SELECT Id, Name
                FROM PermissionSet
                WHERE Name = :PERMISSION_SET_NAME
                LIMIT 1
            ];

            results = [
                SELECT Id, PermissionSetId, AssigneeId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                    AND PermissionSetId = :ps.Id 
                LIMIT 1
            ];
            
            if(results.size() > 0){
                System.debug('User is already assigned to the PermissionSet');
            } else {
                results = new PermissionSetAssignment[]{
                    new PermissionSetAssignment( PermissionSetId = ps.Id, AssigneeId = UserInfo.getUserId() )
                };

                insert results;
            }
        } catch(Exception err){
            //-- do nothing
            System.debug('ERROR - could not assign user to permission set');
            System.debug(err.getMessage());
        }
    }
    
    
    //--	-	-	-	-	-	-	-	-	-	-	-	-	-	-	-	-	-
    
    
    /**
     * Internal class that represents an item to be completed.
     **/
    global class SetupStep {
        
    	/** Title of the Step being run. (Should be short) **/
        @AuraEnabled
        global String title;
        
        /** Longer form description of what will be run.
        	(Hidden if not provided)
        **/
        @AuraEnabled
        global String descr;
        
        /** Reasoning of why the step is needed.
        	(Hidden if not provided)
        **/
        @AuraEnabled
        global String reasoning;
        
        /** Additional detail to show the end user after the step.
        	(ex: Link to the object created, etc.)
        **/
        @AuraEnabled
        global String seeMore;
        
        /** Short label to provide back to the user after completing the step. **/
        @AuraEnabled
        global String seeMoreLabel;
        
        //-- properties set after attempt
    	
    	/** Whether the step is complete
    		(typically only set through markComplete())
    	**/
        @AuraEnabled
        global boolean isComplete;
        
        /** End user readible error found when running the step
        	(typically not initialized, only set afterwards)
        **/
        @AuraEnabled
        global String errMsg;
        
        /** Developer level error found when running the step
        	(typically not initialized, only set afterwards)
        **/
        @AuraEnabled
        global String devErrMsg;
        
        /** DateTime when the step completed.
    		(typically only set through markComplete())
    	**/
        @AuraEnabled
        global String completionDate;

        SetupStep( Map<String,Object> props){
            //-- make similar to sObject inline definition
            if( props.containsKey('title')){
                this.title = (String)props.get('title');
            }
            if( props.containsKey('descr')){
                this.descr = (String)props.get('descr');
            }
            if( props.containsKey('reasoning')){
                this.reasoning = (String)props.get('reasoning');
            }
            if( props.containsKey('seeMore')){
                this.seeMore = (String)props.get('seeMore');
            }
            if( props.containsKey('seeMoreLabel')){
                this.seeMoreLabel = (String)props.get('seeMoreLabel');
            }
            
            //-- not likely, but available if desired
			if( props.containsKey('isComplete')){
                this.isComplete = (boolean)props.get('isComplete');
            }
            if( props.containsKey('errMsg')){
                this.errMsg = (String)props.get('errMsg');
            }
            if( props.containsKey('devErrMsg')){
                this.devErrMsg = (String)props.get('devErrMsg');
            }
            if( props.containsKey('completionDate')){
                this.completionDate = (String)props.get('completionDate');
            }
        }
        
        /**
         * Mark the step as completed.
         * @invariant - marked completed with a current completion date.
         **/
        void markCompleted(){
            this.isComplete = true;
            this.completionDate = System.now().format();
        }
    }
}