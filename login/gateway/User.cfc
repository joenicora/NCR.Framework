component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.User');

	public com.ncr.login.gateway.User function init() {
		super.init();
		
		return this;
	}
}