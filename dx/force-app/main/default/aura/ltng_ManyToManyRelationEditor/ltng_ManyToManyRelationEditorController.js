({
  init : function(component, event, helper){
		console.info('Component initialized');
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
      console.error("error occurred");
      debugger;
    } else if( changeType === "LOADED" ){
      console.info( "recordLoaded" );
      helper.handleRecordLoaded(component, event, helper);
    } else if( changeType === "REMOVED" ){
      helper.displayError('RecordUpdate Removed', component, event, helper);
      debugger;
    } else if( changeType === "CHANGED" ){
      //-- called when updated internally
      //console.info( "record was changed" );
    } else {
      helper.displayError('Unexpected RecordUpdate:' + changeType, component, event, helper);
      debugger;
    }
	},
	
	handleLeftSelected : function(component, event, helper){
		console.log('sObject was selected');
		var leftSObject = component.find('leftObjectSelector').get('v.value');
		// var rightSObject = component.find('rightObjectSelector').get('v.value');
		
		helper.retrieveJunctionObjects(component, helper, leftSObject);
	},

	handleJunctionSelected : function(component, event, helper){
		console.log('junction was selected');
	},

	handleRightSelected : function(component, event, helper){
		console.log('right was selected');
	}
})