component extends = 'com.ncr.abstract.Gateway' {
	
	variables.model = application.new('com.ncr.login.dao.Entity');

	public com.ncr.login.gateway.Entity function init() {
		super.init();
		
		return this;
	}
}