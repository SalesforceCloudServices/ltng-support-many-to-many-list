({
		initializeComponent : function(component, helper){
			helper.noop();

			$A.log('initializeComponent');

			var childRelationship = component.get('v.childrenRelationship');
			if ( childRelationship) {
				var fields = childRelationship.junctionObjectFields;
				$A.log(fields);
				var junctionFields = component.get('v.childrenRelationship.junctionObjectSpecificFields').split(';');
				component.set('v.junctionFields', junctionFields);
			}
		},

		//-- convenience functions
		noop : function(){}
})