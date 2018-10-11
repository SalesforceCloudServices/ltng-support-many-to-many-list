({
	initializeComponent : function(component, helper){
		helper.noop();

		component.set('v.fieldDelimiter', ';');

		var preSelectedFields = component.get('v.preSelectedFields');
		if (preSelectedFields) {
			helper.explodePreSelectedFields(component, helper);
		}
	},

	toggleSectionHeader : function(component, helper){
		helper.noop();
    var isExpanded = component.get('v.isExpanded');
    component.set('v.isExpanded', !isExpanded);
	},

	/**
	 * Ensure that the selected values match the current inputs.
	 */
	refreshSelectedValues : function(component, helper){
		helper.noop();

		//var useCompactLayout = component.find('useCompactLayout').get('v.value');
		//-- no need to assign as they are linked.

		var fieldDelimiter = component.get('v.fieldDelimiter');

		var specificFieldsInput = component.find('specificFields');
		if (specificFieldsInput){
			var selectedFieldsList = specificFieldsInput.get('v.value');
			if (!selectedFieldsList) {
				component.set('v.specificFields', null);
			} else {
				component.set('v.specificFields', selectedFieldsList.join(fieldDelimiter));
			}
		}
	},

	/**
	 * Attempts to explode the list of pre-selected fields
	 */
	explodePreSelectedFields : function(component, helper){
		helper.noop();

		var fieldDelimiter = component.get('v.fieldDelimiter');

		var preSelectedFields = component.get('v.preSelectedFields');
		var preSelectedOptions = null;
		if (preSelectedFields) {
			preSelectedOptions = preSelectedFields.split(fieldDelimiter);
		}

		component.set('v.preSelectedOptions', preSelectedOptions);
	},

	/**
	 * performs a server side call
	 * @param exampleRecordId (Id)
	 **/
	getSObjectFields : function(component, helper, sObjectApiName) {
  	var action = component.get('c.getSObjectFieldOptions');
  	action.setParams({ sObjectApiName: sObjectApiName });
  	
  	action.setCallback(this, function(response){
    	var state = response.getState();
    	if( state === 'SUCCESS' ){
      	$A.log('action success');
				var results = response.getReturnValue();
				component.set('v.specificFieldOptions', results);
    	} else {
      	$A.warning('Error occurred from Action');
      	
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
  
  $A.warning(errorMessages);
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

	//-- convenience methods
	noop : function(){}
})