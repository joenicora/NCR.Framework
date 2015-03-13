component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.log.dao.Log');

	public com.ncr.log.gateway.Log function init() {
		super.init();
		
		return this;
	}
}