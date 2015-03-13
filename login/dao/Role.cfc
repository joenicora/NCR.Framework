component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	
	property type = 'numeric' name = 'role_id';
	property type = 'string' name = 'label';
	property type = 'string' name = 'description';
	property type = 'numeric' name = 'level';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	property array permission;
	
	variables.mapping = {
		'name' = 'role',
		'tableName' = 'role',
		'primaryKey' = 'role_id',
		
		'belongsTo' = {
			'user' = {
				'object' = 'com.ncr.login.dao.User',
				'id' = 'user_id'
			}
		},
		
		'hasMany' = {
			'permission' = {
				'object' = 'com.ncr.login.dao.Permission'
			}
		},
		
		'manyToMany' = {
			'feature_role_permission_map' = {
				'permission' = 'com.ncr.login.dao.Permission',
				'feature' = 'com.ncr.login.dao.Feature'
			},
			'user_role_map' = {
				'user' = 'com.ncr.login.dao.User'
			}
		},
		
		'defaultValues' = {
			'created_date' = '[CURRENT_DATETIME]'
		},
		
		'requirements' = {
			'label' = { 'allowBlank' = false }
		},
		
		'preprocessors' = {}
	};
	
	public com.ncr.login.dao.Role function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
}