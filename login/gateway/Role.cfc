component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.Role');

	public com.ncr.login.gateway.Role function init() {
		super.init();
		
		return this;
	}
}