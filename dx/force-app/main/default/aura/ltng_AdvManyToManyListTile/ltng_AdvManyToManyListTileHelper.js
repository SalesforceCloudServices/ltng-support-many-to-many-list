({
	initializeComponent : function(component, helper){
		helper.noop();

		$A.log('initializeComponent');

		var childRelationship = component.get('v.childrenRelationship');
		if ( childRelationship) {
			var fields = childRelationship.junctionObjectFields;
			$A.log(fields);
			var junctionFields = helper.safeSplit(
				component.get('v.childrenRelationship.junctionObjectSpecificFields'),
				';'
			);
			component.set('v.junctionFields', junctionFields);
		}
	},

	/**
	 * Safely split a string by a delimiter
	 */
	safeSplit : function(str, delimiter){
		var results = [];

		if (str){
			results = str.split(delimiter);
		}

		return results;
	},
	
	/**
	 * Navigates to the record.
	 */
	navigateToRecord : function(component, helper){
		helper.noop();
		
		var recordId = component.get('v.recordId');
		var event = $A.get('e.force:navigateToSObject');
		event.setParams({
			recordId: recordId
		});
		event.fire();
	},
	
	/**
	 * Navigates the user to the junction object
	 **/
	navigateToJunction : function(component, helper) {
		helper.noop();

		var recordId = component.get('v.junctionId');
		var event = $A.get('e.force:navigateToSObject');
		event.setParams({
			recordId: recordId
		});
		event.fire();
	},

	//-- convenience functions
	noop : function(){}
})