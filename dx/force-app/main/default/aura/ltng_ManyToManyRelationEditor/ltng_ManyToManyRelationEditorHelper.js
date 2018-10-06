({
	/**
	 * Initialize the component.
	 */
	initialize : function(component, helper){
		component.set('v.sobjectList', null);
	},

  /**
   * performs a server side call
   * @param exampleRecordId (Id)
   **/
  retrieveSObjectList : function(component, helper, recordId) {
    var action = component.get('c.getListOfAllObjects');
    //action.setParams({ recordId: recordId });
    
    action.setCallback(this, function(response){
      var state = response.getState();
      if( state === 'SUCCESS' ){
        console.info('action success');
				var results = response.getReturnValue();
        component.set('v.sobjectList', results);
        //component.set('v.junctionList', results);
      } else {
        console.error('Error occurred from Action');
        
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
	retrieveJunctionObjects : function(component, helper, leftSObject, rightSObject){

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
						console.info('action success');
            var results = response.getReturnValue();
            component.set('v.junctionList', results);
            
            if (results && results.length === 1){
              component.set('v.selectedJunctionOption', results[0]);
            }
				} else {
						console.error('Error occurred from Action');
						
						//-- https://developer.salesforce.com/blogs/2017/09/error-handling-best-practices-lightning-apex.html
						var errors = response.getError();
						helper.handleCallError(component, helper, state, errors);
				}
		});
		//-- optionally set storable, abortable, background flags here
		$A.enqueueAction(action);
  },
  
  /**
   * Selecting the junction object, what are the standard objects we likely want.
   */
  
  /**
   * Called when the lightning data service loads records.
   **/
  handleRecordLoaded : function(component, event, helper) {
		var leftObjectApiName = component.get('v.ticketRecord.LeftObjectAPIName__c');
		var rightObjectApiName = component.get('v.ticketRecord.RightObjectAPIName__c');
		var junctionObjectApiName = component.get('v.ticketRecord.JunctionObjectAPIName__c');
		
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
  	
  	console.error(errorMessages);
  },
  
  /**
   * Displays an error
   * @param errorTitle (String)
   * @param errorMsg (String)
   **/
  displayError: function(errorCode, component, event, helper){
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
  }
})