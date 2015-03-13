component {
	
	variables.subscribers = [];
	
	public com.ncr.Subscriber function init() {
		variables.subscribers = [{
			subject = {
				cfc = 'com.qt.message.dao.Message',
				method = 'save'
			},
			handler = {
				cfc = 'com.qt.message.dao.Message',
				method = 'publish'
			}
		},{
			subject = {
				cfc = 'com.ncr.security.Manager',
				method = 'auth'
			},
			handler = {
				cfc = 'com.qt.message.dao.Message',
				method = 'supportAvailable'
			}
		}];

		return this;
	}
	
	public array function getSubscribers() {
		return variables.subscribers;
	}
	
}