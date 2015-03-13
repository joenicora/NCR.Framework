component {
	// level: 0=error,1=warning,2=debug,3=info,4=trace
	public com.ncr.log.Manager function init() {
		return this;
	}
	
	public any function write(log) {
		local.logArray = ((isArray(arguments.log)) ? arguments.log : [arguments.log]);
		local.log = application.new('com.ncr.log.dao.log');
		local.log.save(local.logArray);
	}
}