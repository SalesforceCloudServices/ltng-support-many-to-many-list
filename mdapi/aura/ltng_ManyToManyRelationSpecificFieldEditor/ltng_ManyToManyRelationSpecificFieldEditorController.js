({
		init : function(component, event, helper){
				$A.log('Component initialized');
				helper.initializeComponent(component, helper);

				var sObjectApiName = component.get('v.sObjectApiName');
				if (sObjectApiName) {
					//-- get the fields
					helper.getSObjectFields(component, helper, sObjectApiName);
				}
		},

		/**
		 * Called when the section header is clicked.
		 */
		handleSectionHeaderClicked : function(component, event, helper){
			helper.toggleSectionHeader(component, helper);
		},

		/**
		 * Called when the sObject is set or changed
		 */
		handleSObjectChanged : function(component, event, helper){
			var sObjectApiName = component.get('v.sObjectApiName');
			helper.getSObjectFields(component, helper, sObjectApiName);
		},

		/**
		 * Called when the pre-selected fields change.
		 */
		handlePreSelectedFieldsChanged : function(component, event, helper){
			helper.explodePreSelectedFields(component, helper);
		},

		/**
		 * Method to ensure that the attributes of the component are accurate
		 * to the selections made.
		 */
		executeRefreshSelectedValues : function(component, event, helper){
			$A.log('refreshing selected values');

			helper.refreshSelectedValues(component, helper);
		}
})