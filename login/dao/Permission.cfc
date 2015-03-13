component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	
	property type = 'numeric' name = 'permission_id';
	property type = 'string' name = 'label';
	property type = 'string' name = 'description';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	variables.mapping = {
		'name' = 'permission',
		'tableName' = 'permission',
		'primaryKey' = 'permission_id',

		'manyToMany' = {
			'feature_role_permission_map' = {
				'role' = 'com.ncr.login.dao.Role',
				'feature' = 'com.ncr.login.dao.Feature'
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
	
	public com.ncr.login.dao.Permission function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
}