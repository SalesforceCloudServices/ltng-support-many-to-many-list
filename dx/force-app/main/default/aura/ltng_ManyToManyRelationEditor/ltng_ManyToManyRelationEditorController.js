({
  init : function(component, event, helper){
    $A.log('Component initialized');
    
    //-- allow for defaulting while testing.
    //component.set('v.leftObjectApiName', 'ltng_M2M_Account__c');
    //component.set('v.junctionObjectApiName', 'ltng_M2M_AccountContactRelation__c');
    //component.set('v.rightObjectApiName', 'ltng_M2M_Contact__c');

		helper.initialize(component, helper);
		helper.retrieveSObjectList(component, helper);
  },

  /**
   * Handles when the Lightning Data Service record changes
   **/
  recordUpdated : function(component, event, helper){
    var changeType = event.getParams().changeType;
    
    if( changeType === "ERROR" ){
      helper.displayError('RecordUpdate Error', component, event, helper);
      $A.error("error occurred");
      //debugger;
    } else if( changeType === "LOADED" ){
      $A.log( "recordLoaded" );
      helper.handleRecordLoaded(component, event, helper);
    } else if( changeType === "REMOVED" ){
      helper.displayError('RecordUpdate Removed', component, event, helper);
      //debugger;
    } else if( changeType === "CHANGED" ){
      //-- called when updated internally
      //$A.log( "record was changed" );
    } else {
      helper.displayError('Unexpected RecordUpdate:' + changeType, component, event, helper);
      //debugger;
    }
	},
	
	handleLeftRightSelected : function(component, event, helper){
		$A.log('sObject was selected');
		var leftSObject = component.find('leftObjectSelector').get('v.value');
		var rightSObject = component.find('rightObjectSelector').get('v.value');
		
		helper.retrieveJunctionObjects(component, helper, leftSObject, rightSObject);
	},

	handleJunctionSelected : function(component, event, helper){
    helper.noop();

    $A.log('junction was selected');
    var junctionSObject = component.find('junctionObjectSelector').get('v.value');

    var junctionOptions = component.get('v.junctionList');
    var junctionOption = helper.findJunction(component, helper, junctionSObject);
    if (junctionOption) {
      component.set('v.selectedJunctionOption', junctionOption);
    }
    
    return;
	},
  
  handleToggleHelpSection : function(component, event, helper){
    helper.noop();
    var isExpanded = component.get('v.helpExpanded');
    component.set('v.helpExpanded', !isExpanded);
  },

  handleCancel : function(component, event, helper){
    helper.noop();

    var navigateEvent = $A.get("e.force:navigateToObjectHome");
    navigateEvent.setParams({ "scope": component.get('v.sObjectName') });
    navigateEvent.fire();
  },

  handleSave : function(component, event, helper){
    $A.log("handling save");

    var relationshipAlias = component.get('v.relationshipAlias');
    var selectedJunctionOption = component.get('v.selectedJunctionOption');

    if( !relationshipAlias || !selectedJunctionOption){
      return;
    }

    helper.saveRecord(component, helper, relationshipAlias, selectedJunctionOption);
  }
})