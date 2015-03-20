/*
application.observable.observe({
	cfc = 'com.ncr.login.dao.User',
	method = 'save'
},{
	cfc = 'com.qt.message.dao.Message',
	method = 'publish',
	options = {}
});

application.observable.notify({
	cfc = 'com.ncr.login.dao.User',
	method = 'save'
},{
	scope = this,
	data = 
});

application.observable.unobserve({
	cfc = 'com.ncr.login.dao.User',
	method = 'save'
});
*/

component {
	
	public com.ncr.Observable function init() {
		return this;
	}
	
	public void function addSubscriber(subscriber) {
		local.subscriberArray = arguments.subscriber.getSubscribers();
		local.subscriberArrayLen = arrayLen(local.subscriberArray);
		
		for (local.index = 1; local.index <= local.subscriberArrayLen; local.index++) {
			this.observe(local.subscriberArray[local.index].subject, local.subscriberArray[local.index].handler);
		}
	}

	public void function observe(subject, handler) {
		local.key = toKey(arguments.subject);
		
		if (!this.exists(arguments.subject, arguments.handler)) {
			if (application.cache.has(local.key)) {
				local.array = application.cache.get(local.key);
			}
			else {
				local.array = [];
			}
			
			arrayAppend(local.array, arguments.handler);
			
			application.cache.set(local.key, local.array);
		}
	}	
	
	public void function unobserve(subject, handler) {
		local.key = toKey(arguments.subject);
	
		if (application.cache.has(local.key)) {
			local.array = application.cache.get(local.key);
		}
		else {
			local.array = [];
		}
		
		local.arrayLen = arrayLen(local.array);
		
		for (local.index = 1; local.index <= local.arrayLen; local.index++) {
			if (arguments.handler.equals(local.array[local.index])) {
				arrayDeleteAt(local.array, local.index);
			}
		}
		
		application.cache.set(local.key, local.array);		
	}	
	
	public boolean function exists(subject, handler) {
		local.key = toKey(arguments.subject);
	
		if (application.cache.has(local.key)) {
			local.array = application.cache.get(local.key);
		}
		else {
			return false;
		}
		
		local.arrayLen = arrayLen(local.array);
		
		for (local.index = 1; local.index <= local.arrayLen; local.index++) {
			if (arguments.handler.equals(local.array[local.index])) {
				return true;
			}
		}
		
		return false;
	}
	
	public void function notify(subject, information) {
		local.key = toKey(arguments.subject);
	
		if (application.cache.has(local.key)) {
			local.array = application.cache.get(local.key);
		}
		else {
			local.array = [];
		}

		local.arrayLen = arrayLen(local.array);
		
		for (local.index = 1; local.index <= local.arrayLen; local.index++) {
			if (structKeyExists(local.array[local.index], 'options')) {
				arguments.information.options = local.array[local.index].options;
			}		
			
			evaluate('new #local.array[local.index].cfc#().#local.array[local.index].method#(arguments.information)');
			// invoke(local.array[local.index].cfc, local.array[local.index].method, arguments.information);
		}		
				
	}
	
	private string function toKey(subject) {
		return 'observable.' & arguments.subject.cfc & ':' & arguments.subject.method;
	}
	
}