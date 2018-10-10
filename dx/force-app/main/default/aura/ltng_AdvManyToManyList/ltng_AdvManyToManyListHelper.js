({
	/**
	 * Initialize the component
	 */
	initComponent : function(component, helper){
		component.set('v.children', null);

		var deviceType = $A.get("$Browser.formFactor");
		var isDesktop = deviceType === "DESKTOP";
		var numFormColumns = 2;
		if (isDesktop){
			numFormColumns = 2;
		} else {
			numFormColumns = 1;
		}
		component.set("v.isDesktop", isDesktop);
		component.set("v.numFormColumns", numFormColumns);
	},

	/**
	 * Determines the relationships available for the list.
	 * @param recordId (Id)
	 */
	loadRelationships : function(component, helper, recordId){
		var action = component.get('c.listAvailableRelationships');
		action.setParams({ recordId: recordId });

		component.set('v.relationships',null);
		
		action.setCallback(this, function(response){
				var state = response.getState();
				if( state === 'SUCCESS' ){
						console.info('action success');
						var results = response.getReturnValue();
						
						if (results && results.length > 0) {
							component.set('v.relationships', results);
							
							helper.loadChildren(component, helper, recordId, results[0].Id);
						} else {
							component.set('v.relationships',null);
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
	 * performs a server side call
	 * @param exampleRecordId (Id)
	 **/
	loadChildren : function(component, helper, recordId, relationshipId) {
			var action = component.get('c.listChildren');
			action.setParams({ recordId: recordId, relationshipId: relationshipId });
			
			action.setCallback(this, function(response){
					var state = response.getState();
					if( state === 'SUCCESS' ){
							console.info('action success');
							var results = response.getReturnValue();
							component.set('v.children', results);
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
	}
})