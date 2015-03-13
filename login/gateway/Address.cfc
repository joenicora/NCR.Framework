component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.Address');

	public com.ncr.login.gateway.Address function init() {
		super.init();
		
		return this;
	}
}