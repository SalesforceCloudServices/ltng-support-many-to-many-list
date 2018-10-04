({
		init : function(component, event, helper){
				//console.info('Component initialized');
		},

		handleClick : function(component, event, helper){
			var recordId = component.get('v.recordId');
			var event = $A.get('e.force:navigateToSObject');
			event.setParams({
				recordId: recordId
			});
			event.fire();
		}
})