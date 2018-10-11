({
	/**
	 * Initialize the component.
	 */
	initialize : function(component, helper){
    helper.noop();

		component.set('v.sobjectList', null);
	},

  /**
   * performs a server side call
   * @param exampleRecordId (Id)
   **/
  retrieveSObjectList : function(component, helper) {
    var action = component.get('c.getListOfAllObjects');
    //action.setParams({ recordId: recordId });
    
    action.setCallback(this, function(response){
      var state = response.getState();
      if( state === 'SUCCESS' ){
        $A.log('action success');
				var results = response.getReturnValue();
        component.set('v.sobjectList', results);
        //component.set('v.junctionList', results);
      } else {
        $A.log('Error occurred from Action');
        
        //-- https://developer.salesforce.com/blogs/2017/09/error-handling-best-practices-lightning-apex.html
        var errors = response.getError();
        helper.handleCallError(component, helper, state, errors);
      }
    });

    //-- optionally set storable, abortable, background flags here
    $A.enqueueAction(action);
  },
  
  
	
	/**
	 * Selecting both the left and the right, what are the junction objects?
   * @param leftSObject (String) - the api name of the left sobject
   * @param rightSObject (String) - the api name of the right sobject
   * @postcondition - if junction values were found, they are applied to junctionList attr.
	 */
	retrieveJunctionObjects : function(component, helper, leftSObject, rightSObject, preSelectedJunction){

    if (!leftSObject || !rightSObject) {
      //-- we need both to continue.
      return;
    }

		var action = component.get('c.getJunctionRelationships');
    action.setParams({ leftSObject: leftSObject, rightSObject: rightSObject });
    
    component.set('v.junctionList', null);
    component.set('v.selectedJunctionOption', null);

		action.setCallback(this, function(response){
				var state = response.getState();
				if( state === 'SUCCESS' ){
						$A.log('action success');
            var results = response.getReturnValue();
            component.set('v.junctionList', results);
            
            if (results && results.length === 1){
              component.set('v.selectedJunctionOption', results[0]);
            } else if(preSelectedJunction && results.length > 0){
              var defaultedJunction = helper.findJunction(component, helper, preSelectedJunction);
              if (defaultedJunction){
                component.set('v.selectedJunctionOption', defaultedJunction);
              }
            }
				} else {
						$A.log('Error occurred from Action');
						
						//-- https://developer.salesforce.com/blogs/2017/09/error-handling-best-practices-lightning-apex.html
						var errors = response.getError();
						helper.handleCallError(component, helper, state, errors);
				}
		});
		//-- optionally set storable, abortable, background flags here
		$A.enqueueAction(action);
  },

  /**
   * Finds a junction within the list of junctions by the optionApiName
   * @param optionApiName
   */
  findJunction : function(component, helper, optionApiName){
    var junctionOptions = component.get('v.junctionList');

    if (junctionOptions && junctionOptions.length > 0) {
      var junctionOption;
      for (var i = 0; i < junctionOptions.length; i=i+1) {
        junctionOption = junctionOptions[i];
        if (junctionOption.optionApiName === optionApiName) {
          return junctionOption;
        }
      }
    }

    return null;
  },
  
  /**
   * Save the ManyToMany Relationship Record.
   * @param relationshipAlias (String) - the alias of the relationship (to show in the dropdown)
   * @param selectedJunctionOption (ltng_ManyToManyCtrl.ManyToManyRelationOption) - the relationship information.
   */
  saveRecord : function(component, helper, relationshipAlias, selectedJunctionOption){
    
    var relation = {
      "Name": relationshipAlias,
      "LeftObjectAPIName__c": selectedJunctionOption.leftObjectOption.optionApiName,
      "JunctionLeftObjectRelationshipField__c": selectedJunctionOption.leftObjectJunctionField.optionApiName,
      "JunctionObjectAPIName__c": selectedJunctionOption.junctionObjectOption.optionApiName,
      "RightObjectAPIName__c": selectedJunctionOption.rightObjectOption.optionApiName,
      "JunctionRightObjectRelationshipField__c": selectedJunctionOption.rightObjectJunctionField.optionApiName
    };

    var recordId = component.get('v.recordId');
    if (recordId) {
      relation.Id = recordId;
    }
    
    var action = component.get('c.saveM2MRelation');
    action.setParams({ relation: relation });
    
    action.setCallback(this, function(response){
        var state = response.getState();
        if( state === 'SUCCESS' ){
            helper.info('action success');
            var results = response.getReturnValue();
            $A.log(results);

            helper.goBack(component, helper);
        } else {
            $A.error('Error occurred from Action');
            
            //-- https://developer.salesforce.com/blogs/2017/09/error-handling-best-practices-lightning-apex.html
            var errors = response.getError();
            helper.handleCallError(component, helper, state, errors);
        }
    });
    //-- optionally set storable, abortable, background flags here
    $A.enqueueAction(action);
  },

  /**
   * Handles going back.
   */
  goBack : function(component, helper){
    helper.noop();

    var recordId = component.get('v.recordId');
    var sObjectName = component.get('v.sObjectName');
    var navigateEvent;

    if (recordId) {
      // Display popup confirmation to the user
      var resultsToast = $A.get("e.force:showToast");
      resultsToast.setParams({
          "title": "Saved",
          "message": "The record was updated."});
      resultsToast.fire();

      // Navigate back to the record view
      navigateEvent = $A.get("e.force:navigateToSObject");
      navigateEvent.setParams({ "recordId": recordId });
      navigateEvent.fire();
    } else {
      navigateEvent = $A.get("e.force:navigateToObjectHome");
      navigateEvent.setParams({ "scope": sObjectName });
      navigateEvent.fire();
    }
  },
  
  /**
   * Called when the lightning data service loads records.
   **/
  handleRecordLoaded : function(component, event, helper) {
    helper.noop();

    var relationshipAlias = component.get('v.currentRelationship.Name');
		var leftObjectApiName = component.get('v.currentRelationship.LeftObjectAPIName__c');
		var rightObjectApiName = component.get('v.currentRelationship.RightObjectAPIName__c');
    var junctionObjectApiName = component.get('v.currentRelationship.JunctionObjectAPIName__c');
    
    component.set('v.relationshipAlias', relationshipAlias);
    component.set('v.leftObjectApiName', leftObjectApiName);
    component.set('v.rightObjectApiName', rightObjectApiName);
    component.set('v.junctionObjectApiName', junctionObjectApiName);

    helper.retrieveJunctionObjects(component, helper, leftObjectApiName, rightObjectApiName, junctionObjectApiName);
  },
  
  /**
   * Handles the collection of errors into something acceptable for the end user.
   * @param errors (Object[]) - collection of errors from a server side call.
   */
  handleCallError : function(component, helper, state, errors){
  	//-- https://developer.salesforce.com/blogs/2017/09/error-handling-best-practices-lightning-apex.html
  	var errorMessages = [];
  	if( errors && Array.isArray(errors) && errors.length > 0 ){
			errors.forEach(function(error){
				errorMessages.push(error.message);
			});
  	}
  	
  	if( state === 'ERROR' ){
      helper.displayError('Error', 'Action error');
  	} else {
      helper.displayError('Unknown Response', 'Action failure');
  	}
  	
  	$A.log(errorMessages);
  },
  
  /**
   * Displays an error
   * @param errorTitle (String)
   * @param errorMsg (String)
   **/
  displayError: function(errorCode, component, event, helper){
    helper.noop();

    var errorTitle = 'Error';
    var errorMsg = 'An error occurred: ' + errorCode + '. Please contact your System Administrator';
    
    //-- send a toast message
    var resultsToast = $A.get('e.force:showToast');
    resultsToast.setParams({
      'title': errorTitle,
      'message': errorMsg
    });
    resultsToast.fire();
  },
  
  /**
   * Handles when the save has completed
   **/
  handleSaveCompleted : function(component, event, helper) {
    helper.noop();

    //-- send a toast message
    var resultsToast = $A.get('e.force:showToast');
    resultsToast.setParams({
      'title': 'Saved',
      'message': 'The record was saved'
    });
    resultsToast.fire();
    
    //-- refresh the standard detail
    $A.get('e.force:refreshView').fire();
    
    //-- close the dialog
    $A.get("e.force:closeQuickAction").fire();
  },

  noop : function(){},

  log : function(msg){
    $A.log(msg);
  },
  info : function(msg){
    console.info(msg);
  },
  error : function(msg){
    console.error(msg);
  }
})