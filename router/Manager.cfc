component {

	variables.catelog = {};

	public com.ncr.router.Manager function init() {
		local.config = fileRead(application.path.absolute.config & 'router.json');
		variables.catelog = deserializeJson(local.config);
		
		return this;
	}
	
	public string function buildResult(resource, method) {
		local.route = ((len(trim(arguments.resource))) ? variables.catelog.route[arguments.resource] : variables.catelog.route[variables.catelog.defaults.route]);
		request.data.title = '';
		
		if (!len(trim(arguments.resource))) {
			request.route = [variables.catelog.defaults.route];
		}	
		
		// stack
		if (structKeyExists(local.route, 'stack')) {
			local.stackLen = arrayLen(local.route.stack);

			for (local.index = 1; local.index <= local.stackLen; local.index++) {
				if (local.route.stack[local.index] contains ':') {				
					
					local.cfc = listFirst(local.route.stack[local.index], ':');
					local.method = listLast(local.route.stack[local.index], ':');

					local.instance = application.new(local.cfc, {
						route = local.route,
						method = arguments.method
					});

					local.result = invoke(local.instance, local.method, {
						route = local.route,
						method = arguments.method
					}); 
					
					request.data.stack[local.route.stack[local.index]] = local.result;
				}
				else {			
					request.data.stack[local.route.stack[local.index]] = application.new(local.route.stack[local.index], {
						route = local.route,
						method = arguments.method
					});	
				}
			}
		}
		
		if (!structKeyExists(local.route.result, 'type')) {
			local.route.result.type = 'template';
		}
		
		// security filters
		local.security = {};
		local.security.permissions = application.security.getPermissions();
		local.security.filters = application.security.getFilters();
		local.hasPermission = true;

		if (!isBoolean(application.stack.get('application.onRequestStart.Auth'))) {
			// auth failed, set to login default
			local.route = variables.catelog.route[variables.catelog.defaults.login];
			request.route = [variables.catelog.defaults.login];
			arguments.resource = variables.catelog.defaults.login;
		}
		
		if (arguments.resource contains 'secure') {
			local.hasPermission = false;
			
			for (local.index = 1; local.index <= local.security.filters.recordCount; local.index++) {
				if (!structKeyExists(session, 'security')) {
					local.hasPermission = false;
					local.message = 'Your session is no longer active.';
					
					continue;
				}
							
				if (arguments.resource contains local.security.filters.value[local.index]) {
					local.hasPermission = local.security.permissions.can('execute').with(local.security.filters.label[local.index]);

					if (!local.hasPermission) {
						local.message = 'You do not have valid permissions to view this area.';
						
						continue;
					}
				}
			}
		}
		
		if (!local.hasPermission) {
			local.exception = application.new('com.ncr.Exception', {
				label = 'application.onRequestStart',
				level = 'warning',
				message = local.message
			});
			application.stack.set('application.onRequestStart.Auth', local.exception);

			local.route = variables.catelog.route[variables.catelog.defaults.login];
			request.route = [variables.catelog.defaults.login];
		}
		else {
			if (structKeyExists(local.route.result, 'route')) {
				request.route = [local.route.result.route];

				this.buildResult(local.route.result.route, arguments.method);
				
				return true;
			}
		}
		
		if (structKeyExists(local.route, 'title')) {
			request.data.title = local.route.title;
		}
		
		local.pageContextResponse = getPageContext().getResponse();
		local.responseHeader = new com.ncr.wrapper.ResponseHeader();
		
		switch (local.route.result.type) {
			case 'json' : 
				local.pageContextResponse.setContentType('application/json');
				local.responseHeader.setHeader( { name = "expires", value = "#now()#" } );
				local.responseHeader.setHeader( { name = "pragma", value = "no-cache" } );
				local.responseHeader.setHeader( { name = "cache-control", value = "no-cache, no-store, must-revalidate" } );
				
				if (isBoolean(application.stack.get('application.onRequestStart.Auth'))) {
					request.data.content = serializeJson(request.data.stack);	
				}
				else {
					writeoutput(serializeJson({
						'success' = false,
						'error' = application.stack.get('application.onRequestStart.Auth')
					}));
					abort;
				}
				
				break;
				
			case 'xml' : 
				local.pageContextResponse.setContentType('application/xml');
				local.responseHeader.setHeader( { name = "expires", value = "#now()#" } );
				local.responseHeader.setHeader( { name = "pragma", value = "no-cache" } );
				local.responseHeader.setHeader( { name = "cache-control", value = "no-cache, no-store, must-revalidate" } );
				
				local.xmlTrancoder = application.new('com.ncr.xml.Transcoder');
				
				if (isBoolean(application.stack.get('application.onRequestStart.Auth'))) {
					request.data.content = local.xmlTrancoder.toXml(request.data.stack);
				}
				else {
					writeoutput(local.xmlTrancoder.toXml(application.stack.get('application.onRequestStart.Auth')));
					abort;					
				}
				
				break;
			
			case 'javascript' :
				local.pageContextResponse.setContentType('application/javascript');
				local.responseHeader.setHeader( { name = "expires", value = "#now()#" } );
				local.responseHeader.setHeader( { name = "pragma", value = "no-cache" } );
				local.responseHeader.setHeader( { name = "cache-control", value = "no-cache, no-store, must-revalidate" } );

				if (isBoolean(application.stack.get('application.onRequestStart.Auth'))) {				
					savecontent variable = 'request.data.content' {
						include '#application.path.relative.template##local.route.result.template#';
					}
				}
				else {
					writeoutput("
						LAB.view.#request.params.route# = function() {
							return { 
								exception : " & serializeJson(application.stack.get('application.onRequestStart.Auth')) & " 
							}
						};
					");
					abort;
				}
				
				break;
			
			default : 
				try {					
					savecontent variable = 'request.data.content' {
						include '#application.path.relative.template##local.route.result.template#';
					}	
					
					if (structKeyExists(local.route.result, 'layout')) {
						savecontent variable = 'request.data.content' {
							include '#application.path.relative.template##local.route.result.layout#';
						}		
					}
					else {
						savecontent variable = 'request.data.content' {
							include '#application.path.relative.template##variables.catelog.defaults.layout#';
						}					
					}
				}
				catch(any e) {
					/*savecontent variable = 'request.data.content' {
						include '#application.path.relative.template#error.cfm';
					}*/	
					writedump(e);				
				}
				break;
		}
	}
}