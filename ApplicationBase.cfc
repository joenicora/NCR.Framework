component {
	
	this.name = 'NCR.Framework';
    this.applicationTimeout = createTimeSpan(7,0,0,0);
    this.clientManagement = false;
    this.loginStorage = 'session';
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan(0,12,0,0);
    // weird anomolly with this, if you are losing sessions screw with this setting
    this.setClientCookies = true;
    this.setDomainCookies = false;
    this.scriptProtect = false;
    this.secureJSON = false;
    this.secureJSONPrefix = '';
    
	public boolean function onApplicationStart() {
		application.prefix = 'NCR';
		application.token = createUuid();
		application.delim = ((findNoCase('windows', server.os.name)) ? '\' : '/');
		application.path = {
			absolute = { root = expandPath(application.delim) },
			relative = { root = '/' }
		};
		application.path.absolute.log = application.path.absolute.root & 'log' & application.delim;
		application.path.absolute.config = application.path.absolute.root & 'config' & application.delim;
		application.path.relative.template = application.path.relative.root & 'template' & application.delim;
		application.dsn = {
			'default' = 'ncrapp'
		};
		application.seed = 0;
		application.environment = {
			mode = ((server_name == 'localhost') ? 'development' : 'production'),
			version = '1.#dateDiff('s', dateConvert('utc2Local', 'January 1 1970 00:00'), now())#',
			port = ((server_name == 'localhost') ? ':8502' : '')
		};
		application.metrics = {
			activeSessions =  0
		};
		application.communication = {
			bot = 'joenicora@me.com'
		};
		application.logConfig = {
			recordLevel = 3
		};
		
		application.factory = new com.ncr.Factory();
		application.new = application.factory.new;

		application.misc = application.new('com.ncr.util.Misc');
		application.date = application.new('com.ncr.util.Date');
		application.query = application.new('com.ncr.util.Query');
		application.toolbox = application.new('com.ncr.util.Toolbox');
		application.cache = application.new('com.ncr.cache.Manager');
		// application.event = application.new('com.ncr.event.Manager');
		application.observable = application.new('com.ncr.Observable');
		application.security = application.new('com.ncr.security.Manager');
		application.stack = application.new('com.ncr.Stack');
		application.authenticate = application.new('com.ncr.wrapper.Authenticate');
		application.router = application.new('com.ncr.router.Manager');
		application.log = application.new('com.ncr.log.Manager');
		
		application.observable.addSubscriber(application.new('com.ncr.Subscriber'));
		
		application.log.write({
			'level' = 'info',
			'label' = 'application.onApplicationStart',
			'message' = 'Application #this.name# has started.'
		});
		
		return true;
	}
	
	public boolean function onApplicationEnd() {}
	
	public boolean function onRequestStart(targetPage) {
		return true;
	}
	
	public boolean function onRequest(targetPage) {		
		request.route = listToArray(reReplaceNoCase(arguments.targetPage, '.cfm|index', '', 'all'), '/');		
		request.params = {};
		request.params.putAll(url);
		request.params.putAll(form);
		request.data = {
			stack = {}
		};
		
		if (application.environment.mode == 'development') {
			request.params.putAll({
				init = true,
				clearCache = true
			});
		}
		
		if (structKeyExists(request.params, 'init')) {
			this.doInit();
		}
		
		if (structKeyExists(request.params, 'clearCache')) {
			application.cache.removeAll();
		}
		
		if (structKeyExists(request.params, 'kill')) {
			application.security.logout();
		}		
		
		application.router.buildResult(((arrayLen(request.route)) ? request.route[1] : ''), getHTTPRequestData().method);
		
		getPageContext().getCFOutput().print(request.data.content);
		
		return true;
	}
	
	public void function onRequestEnd(targetPage) {}
	
	public void function onSessionStart() {
		application.metrics.activeSessions++;
	}	
	
	public void function onSessionEnd(sessionScope) {
		application.metrics.activeSessions--;
		structDelete(application.support.admins, sessionScope.security.user.user_id);
	}
	
	public boolean function onMissingTemplate(targetPage) {
		this.onRequestStart(arguments.targetPage);
		this.onRequest(arguments.targetPage);
		
		return true;
	}
	
	public any function onError(exception, eventName) {
		// writeoutput('Application.onError');
		writedump(arguments);
		// TODO failsafe error checking
		// idea: create exception handlers in the config (ie: under config have an exception.json where you can define how to handle exception types)
	}
	
	public void function doInit() {
		for (local.key in application) {
			structDelete(application, local.key);
		}

		this.onApplicationStart();
	}
}
