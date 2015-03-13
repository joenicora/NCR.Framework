component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.Permission');

	public com.ncr.login.gateway.Permission function init() {
		super.init();
		
		return this;
	}
}