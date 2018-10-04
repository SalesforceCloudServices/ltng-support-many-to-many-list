({
		init : function(component, event, helper){
				console.info('Component initialized');

				var recordId = component.get('v.recordId');

				helper.initComponent(component, helper);
				helper.loadChildren(component, helper, recordId);
		}
})