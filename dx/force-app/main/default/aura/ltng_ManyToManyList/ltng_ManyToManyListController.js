({
		init : function(component, event, helper){
				console.info('Component initialized');

				var recordId = component.get('v.recordId');

				helper.initComponent(component, helper);
				//helper.loadChildren(component, helper, recordId);

				helper.loadRelationships(component, helper, recordId);
		},

		handleRelationshipChanged : function(component, event, helper){
			var relationshipId = component.find('relationshipSelector').get('v.value');
			var recordId = component.get('v.recordId');
			helper.loadChildren(component, helper, recordId, relationshipId);
		}
})