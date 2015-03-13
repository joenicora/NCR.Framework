component {
	
	/*
		// Example usage
		// instantiate
		application.EvtMgr = new com.market.abstract.EventManager();
		
		// add events
		application.EvtMgr.addEvents([ 
			{ event = 'error' }
		]);
		
		// subscribe
		application.EvtMgr.on('error', { 
			classPath = 'lib.Error', 
			[reference] = object
			methodName = 'notify', 
			argumentCollection = {} 
		});
		
		// fire event
		application.EvtMgr.fireEvent('error', exception);
	
	*/
	
	variables.collection = {};
	
	public com.ncr.event.Manager function init(config = {}) {
		variables.collection.putAll(arguments.config);
		return this;
	}
	
	public any function addEvents(required array events) {
		local.events = arguments.events;
		local.len = arrayLen(arguments.events);
		
		for (local.ix = 1; local.ix <= local.len; local.ix++) {
			variables.collection[local.events[local.ix].event] = [];
		}
		
		return this;
	}
	
	public any function on(required string event, required struct callback) {
		local.event = ((structKeyExists(variables.collection, arguments.event)) ? variables.collection[arguments.event] : (this.addEvents([ { event = arguments.event } ])));

		if (isArray(local.event)) {
			arrayAppend(local.event, arguments.callback);
			variables.collection[arguments.event] = local.event;
		}
		
		return this;
	}
	
	public any function fireEvent(required string event, struct options) {
		local.events = variables.collection;
		local.eventArr = local.events[arguments.event];
		local.ix = 1;
		local.len = arrayLen(local.eventArr);
		local.response = [];

		for (local.ix = 1; local.ix <= local.len; local.ix++) {
			local.argumentCollection = structAppend(local.eventArr[local.ix].argumentCollection, arguments.options);
			
			local.eventArr[local.ix].argumentCollection.putAll({
				eventManager = this
			});
			
			try {
				if (structKeyExists(local.eventArr[local.ix], 'classPath')) {
					local.response[local.ix] = evaluate('new ' & local.eventArr[local.ix].classPath & '().' & local.eventArr[local.ix].methodName & '(argumentCollection = local.eventArr[local.ix].argumentCollection)');	
				}
				else {
					local.object = local.eventArr[local.ix].reference;
					local.response[local.ix] = evaluate('local.object.' & local.eventArr[local.ix].methodName & '(argumentCollection = local.eventArr[local.ix].argumentCollection)');	
				}
			} catch(Any e) {
				return application.new('com.ncr.Exception', {
					level = 'error',
					label = 'com.ncr.event.Manager.fireEvent',
					message = 'Error caught while invoking callback  object.',
					detail = serializeJson({ arguments = arguments })
				});
			}
			
			if (local.response[local.ix] == false) {
				return false;
			}
		}
	
		return this;
	}
}