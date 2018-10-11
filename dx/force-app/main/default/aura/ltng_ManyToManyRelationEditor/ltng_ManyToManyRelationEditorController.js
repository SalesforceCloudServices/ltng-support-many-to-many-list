({
  init : function(component, event, helper){
    //$A.log('Component initialized');

		helper.initialize(component, helper);
		helper.retrieveSObjectList(component, helper);
  },

  /**
   * Lightning Data Service handling
   * <p>Used for the values used during 'edit' mode.</p>
   **/
  recordUpdated : function(component, event, helper){
    var changeType = event.getParams().changeType;
    
    if( changeType === "ERROR" ){
      helper.displayError('RecordUpdate Error', component, event, helper);
      $A.warning("error occurred when loading the record");
      //debugger;
    } else if( changeType === "LOADED" ){
      //$A.log( "recordLoaded" );
      helper.handleRecordLoaded(component, event, helper);
    } else if( changeType === "REMOVED" ){
      //helper.displayError('RecordUpdate Removed', component, event, helper);
      //debugger;
    } else if( changeType === "CHANGED" ){
      //-- called when updated internally
      //$A.log( "record was changed" );
    } else {
      helper.displayError('Unexpected RecordUpdate:' + changeType, component, event, helper);
      //debugger;
    }
	},
  
  /**
   * Handle when either the left or the right side objects are selected.
   */
	handleLeftRightSelected : function(component, event, helper){
		var leftSObject = component.find('leftObjectSelector').get('v.value');
		var rightSObject = component.find('rightObjectSelector').get('v.value');
		
		helper.retrieveJunctionObjects(component, helper, leftSObject, rightSObject);
	},

  /**
   * Handle when the junction object has been chosen.
   * <p>Junction objects are only available after the left and right are chosen.
   */
	handleJunctionSelected : function(component, event, helper){
    helper.noop();

    var junctionSObject = component.find('junctionObjectSelector').get('v.value');

    var junctionOption = helper.findJunction(component, helper, junctionSObject);
    if (junctionOption) {
      component.set('v.selectedJunctionOption', junctionOption);
    }
    
    return;
	},
  
  /**
   * Handles the Help Section button toggle.
   */
  handleToggleHelpSection : function(component, event, helper){
    helper.noop();
    var isExpanded = component.get('v.helpExpanded');
    component.set('v.helpExpanded', !isExpanded);
  },

  /**
   * Handles the 'Cancel' button press
   */
  handleCancel : function(component, event, helper){
    helper.noop();

    var navigateEvent = $A.get("e.force:navigateToObjectHome");
    navigateEvent.setParams({ "scope": component.get('v.sObjectName') });
    navigateEvent.fire();
  },

  /**
   * Handles the 'Save' button press
   */
  handleSave : function(component, event, helper){
    var relationshipAlias = component.get('v.relationshipAlias');
    var selectedJunctionOption = component.get('v.selectedJunctionOption');

    if( !relationshipAlias || !selectedJunctionOption){
      return;
    }

    helper.saveRecord(component, helper, relationshipAlias, selectedJunctionOption);
  }
})