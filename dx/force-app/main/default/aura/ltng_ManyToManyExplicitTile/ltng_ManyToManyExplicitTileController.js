({
		init : function(component, event, helper){
				$A.log('Component initialized');
				helper.initializeComponent(component, helper);
		},

		handleObjectClick : function(component, event, helper){
			helper.navigateToRecord(component, helper);
		},
	
		handleJunctionClick : function(component, event, helper){
			helper.navigateToJunction(component, helper);
		}
})