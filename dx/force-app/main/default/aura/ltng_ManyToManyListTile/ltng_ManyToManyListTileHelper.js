({
	/**
	 * Navigates to the record.
	 */
	navigateToRecord : function(component, helper){
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
		var recordId = component.get('v.junctionId');
		var event = $A.get('e.force:navigateToSObject');
		event.setParams({
			recordId: recordId
		});
		event.fire();
	}
})