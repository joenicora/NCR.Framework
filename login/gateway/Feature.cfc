component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.Feature');

	public com.ncr.login.gateway.Feature function init() {
		super.init();
		
		return this;
	}
}