component {
	public com.ncr.security.Manager function init() {
		return this;
	}
	
	variables.userModel = application.new('com.ncr.login.dao.User');
		
	public any function auth(param) {
		local.matches = arguments.param.matches;
		
		local.user = variables.userModel.load(local.matches[1][variables.userModel.getMapping().primaryKey], { 
			loadMap = true,
			include = ['role']
		});
		local.user.setUserGroup(local.user.getParent('userGroup'));
		local.user.setEntity(local.user.getParent('entity'));
		// local.userStruct = local.user.getStruct();
		
		application.authenticate.login({
			name = '#local.user.getUserName()#',
			password = '#local.user.getPassword()#',
			roles = '#arrayToList(local.user.getMap()["user_role_map"].role)#'
		});
		
		local.key = generateSecretKey('DESEDE');
		local.token = encrypt(local.user.getUsername(), local.key, 'DESEDE', 'HEX');
	
		session.security = {
			user = local.user,
			token = local.token
		};
		this.setPolicy(this.getPolicy(local.user));
		
		return {
			'user' = local.user,
			'token' = local.token,
			'sessionId' = session.sessionId,
			'success' = true
		};
	}
	
	public any function login(param) {
		local.userGateway = application.new('com.ncr.login.gateway.User');
		
		local.matches = local.userGateway.readBy({
			where = "
				user.username = :username and 
				user.password = :password and
				user.active = :active
			",
			limit = "1",
			params = {
				username = {
					value = arguments.param.username
				},
				password = {
					value = variables.userModel.hashPassword(arguments.param.password)
				},
				active = {
					value = 1,
					cftype = 'boolean'
				}
			}
		}, { loadMap = true });
		
		lock scope = 'application' type = 'exlusive' timeout = '10' {
			if (arrayLen(local.matches)) {
				
				application.log.write({
					'level' = 'info',
					'label' = 'com.ncr.security.Manager.auth',
					'message' = 'User #local.matches[1].full_name# logged in.'
				});
						
				return this.auth({
					matches = local.matches
				});	
			}
			else {
				local.message = 'Invalid credentials.';
			
				local.exception = application.new('com.ncr.Exception', {
					label = 'com.security.login.invalidCredentials',
					level = 'warning',
					message = local.message
				});
		
				return local.exception;
			}
		}
	}
	
	public void function logout() {
		lock scope = 'application' type = 'exlusive' timeout = '10' {
			application.authenticate.logout();
			structDelete(session, 'security');
		}
	}
	
	public any function getPermissions(param) {
		if (len(trim(getAuthUser()))) {
			policy = session.security.policy;
			
			local.result = application.query.run({
				datasource = application.dsn.default,
				sql = "select featureLabel, permissionLabel from policy",
				dbType = 'query',
				policy = policy
			}).getResult();
			
			local.permissions = {};
			
			for (local.index = 1; local.index <= local.result.recordCount; local.index++) {
				if (!structKeyExists(local.permissions, local.result.featureLabel[local.index])) {
					local.permissions[local.result.featureLabel[local.index]] = [];	
				}
				arrayAppend(local.permissions[local.result.featureLabel[local.index]], local.result.permissionLabel[local.index]);
			}

			return application.new('com.ncr.security.Object', local.permissions);	
		}
		else {
			/*application.new('com.ncr.Exception', {
				label = 'com.security.Manager.request',
				level = 'trace',
				message = 'Request made with invalid auth user.',
				detail = serializeJson({ arguments = arguments })
			});*/
			
			return application.new('com.ncr.security.Object');
		}
	}
	
	public void function setPolicy(policy) {
		session.security.policy = arguments.policy;
	}
	
	public query function getPolicy(user) {
		local.userGateway = application.new('com.ncr.login.gateway.User');
		
		local.policy = local.userGateway.queryBy({
			select = " distinct user.*, role.role_id, role.label as roleLabel, feature.feature_id, feature.filter, feature.label as featureLabel, permission.permission_id, permission.label as permissionLabel, feature.value as featureValue",
			mapTo = [{
				gateway = 'com.ncr.login.gateway.Role',
				map = 'feature_role_permission_map'
			}],
			where = "user.user_id = :user_id and role.role_id in (:role_id)",
			params = {
				user_id = {
					value = arguments.user.getUser_id(),
					cftype = 'numeric'
				},
				role_id = {
					value = arrayToList(arguments.user.getMap().user_role_map.role)
				}
			}
		},{
			loadMap = true
		});
		
		return local.policy;
	}
	
	public query function getFilters() {
		if (!application.cache.has('filters')) {
			local.featureGateway = application.new('com.ncr.login.gateway.Feature');
			
			local.filters = local.featureGateway.queryBy({
				where = "filter = 'url'"
			});
			
			application.cache.set('filters', local.filters);
		}
		else {
			local.filters = application.cache.get('filters');
		}
		
		return local.filters;
	}
}