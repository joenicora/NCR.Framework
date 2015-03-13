component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.UserGroup');

	public com.ncr.login.gateway.UserGroup function init() {
		super.init();
		
		return this;
	}
}