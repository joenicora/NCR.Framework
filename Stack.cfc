component {
	public com.ncr.Stack function init() { 
		return this; 
	}
	
	public any function get(item) {
		if (structKeyExists(request.data.stack, arguments.item)) {
			return request.data.stack[arguments.item];
		}
		else {
			return false;
		}
	}
	
	public void function set(item, value) {
		request.data.stack[arguments.item] = arguments.value;
	}
	
	public any function getAll() {
		return request.data.stack;
	}
}