component {

	public com.ncr.cache.Manager function init() {
		return this;
	}
	
	public any function get(key) {
		local.cacheObject = cacheGet(arguments.key);
		
		return ((isNull(local.cacheObject)) ? false : local.cacheObject);
	}
	
	public any function has(key) {
		local.cacheObject = cacheGet(arguments.key);
		
		return ((isNull(local.cacheObject)) ? false : true);
	}
	
	public void function set(key, value, timeSpan) {
		local.timeSpan = ((structKeyExists(arguments, 'timeSpan')) ? arguments.timeSpan : createTimeSpan(0, 1, 0, 0));
		
		cachePut(arguments.key, arguments.value, local.timeSpan);
	}
	
	public void function remove(key) {
		cacheRemove(arguments.key);
	}
	
	public void function removeAll() {
		if (arrayLen(cacheGetAllIds())) {
			cacheRemove(arrayToList(cacheGetAllIds()));	
		}
	}
	
	public array function getKeys() {
		return cacheGetAllIds();
	}

}