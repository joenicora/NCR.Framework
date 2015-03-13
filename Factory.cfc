component {
	
	public com.ncr.Factory function init() {
		return this;
	}
		
	public any function new(cfcPath, config) {
		local.config = ((structKeyExists(arguments, 'config')) ? arguments.config : {});
		
		return createObject(cfcPath).init(local.config);
	}
	
}