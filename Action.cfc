component {
	
	public com.ncr.Action function init() { return this; }
	
	public any function updateSession(params) {

		local.exception = application.new('com.ncr.Exception', {
			label = 'application.onRequestStart',
			level = 'warning',
			message = 'Your session information needs to be updated, please log back in.'
		});
		application.stack.set('application.onRequestStart.Auth', local.exception);
		
		application.cache.remove('com.ncr.login.dao.User.pendingChanges.#session.security.user.user_id#');
	}
	
	public any function logout(params) {

		local.exception = application.new('com.ncr.Exception', {
			label = 'application.onRequestStart',
			level = 'warning',
			message = 'This account has been deactivated.'
		});
		application.stack.set('application.onRequestStart.Auth', local.exception);
		
		application.cache.remove('com.ncr.login.dao.User.pendingChanges.#session.security.user.user_id#');
	}
	
}