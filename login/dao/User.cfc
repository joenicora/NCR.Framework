component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	
	property type = 'numeric' name = 'user_id';
	property type = 'numeric' name = 'user_group_id';
	property type = 'numeric' name = 'entity_id';
	property type = 'string' name = 'username';
	property type = 'string' name = 'password';
	property type = 'string' name = 'full_name';
	property type = 'boolean' name = 'active';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	property type = 'com.ncr.login.dao.UserGroup' name = 'userGroup';
	property type = 'com.ncr.login.dao.Entity' name = 'entity';
	
	property array role;
	
	variables.mapping = {
		'name' = 'user',
		'tableName' = 'user',
		'primaryKey' = 'user_id',

		'belongsTo' = {
			'userGroup' = {
				'object' = 'com.ncr.login.dao.UserGroup',
				'id' = 'user_group_id'
			},
			'entity' = {
				'object' = 'com.ncr.login.dao.Entity',
				'id' = 'entity_id'
			}
		},
		
		'hasMany' = {
			'role' = {
				'object' = 'com.ncr.login.dao.Role'
			}
		},

		'manyToMany' = {
			'user_role_map' = {
				'role' = 'com.ncr.login.dao.Role'
			}
		},
		
		'defaultValues' = {
			'created_date' = '[CURRENT_DATETIME]',
			'active' = '[TRUE]'
		},
		
		'requirements' = {
			'username' = { 'allowBlank' = false, 'minLength' = 6 },
			'password' = { 'allowBlank' = false }
		},
		
		'preprocessors' = {
			'password' = [
				this.passwordStrength,
				this.hashPassword
			],
			'username' = [
				this.checkDuplicateUsernames
			]
		}
	};
	
	public com.ncr.login.dao.User function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
	
	public any function save() {
		super.save();
		
		// being edited by a user
		if (structKeyExists(session, 'security')) {
			local.editor = {
				user_id = session.security.user.getUser_id()
			};
		}
		else {
			local.editor = {
				user_id = 0
			};
		}
		
		if (this.hasExceptions()) {
			return this;
		}
		
		this.load(this.getUser_id());
			
		if (local.editor.user_id != this.getUser_id()) {
			if (this.getActive()) {
				// forcing people to log back in after an edit from someone else isnt a good idea
				/*application.cache.set('com.ncr.login.dao.User.pendingChanges.#this.getUser_id()#', {
					action = {
						class = 'com.ncr.Action',
						method = 'updateSession',
						params = {}
					}
				});*/	
			}
			else {
				application.cache.set('com.ncr.login.dao.User.pendingChanges.#this.getUser_id()#', {
					action = {
						class = 'com.ncr.Action',
						method = 'logout',
						params = {}
					}
				});	
				
			}	
		}
		else {
			application.security.auth({
				matches = [{ user_id = this.getUser_id() }]
			});
		}
		
		application.observable.notify({
			cfc = 'com.ncr.login.dao.User',
			method = 'save'
		},{
			scope = this
		});
		
		return this;
	}
	
	public string function hashPassword(value) {
		return hash(arguments.value);
	}
	
	public any function passwordStrength(value) {		
		if (
			!(
				len(arguments.value) >= 6 &&
				refind('[a-z]', arguments.value) &&
				refind('[0-9]', arguments.value) /*&&
				refind('[!@##$%^&*]', arguments.value)*/
			)
		) {

			local.exception = application.new('com.ncr.Exception', {
				level = 'error',
				label = 'com.ncr.login.dao.User.passwordStrength',
				message = 'Your password must contain at least one letter and number and be at least 6 characters long.',
				data = { field = 'password' }
			});
			
			return local.exception;
		}
		else {
			return arguments.value;
		}
	}
	
	public any function checkDuplicateUsernames(value) {
		local.userGateway = application.new('com.ncr.login.gateway.User');
		local.user_idCheck = ((isNull(this.getUser_id())) ? '' : 'and user_id <> #this.getUser_id()#');

		local.duplicates = local.userGateway.queryBy(
			{
				where = "username = :username #local.user_idCheck#",
				params = {
					username = {
						value = this.getUsername()
					}
				}
			}
		);
		
		if (local.duplicates.recordCount == 0) {
			return arguments.value;
		}
		else {
			local.exception = application.new('com.ncr.Exception', {
				level = 'error',
				label = 'com.ncr.login.dao.User.checkDuplicateUsernames',
				message = 'This username already exists.',
				data = { field = 'username' }
			});
			
			return local.exception;
		}
	}
	
}