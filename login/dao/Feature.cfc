component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	
	property type = 'numeric' name = 'feature_id';
	property type = 'string' name = 'label';
	property type = 'string' name = 'filter';
	property type = 'string' name = 'value';
	property type = 'string' name = 'description';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	variables.mapping = {
		'name' = 'feature',
		'tableName' = 'feature',
		'primaryKey' = 'feature_id',

		'manyToMany' = {
			'feature_role_permission_map' = {
				'permission' = 'com.ncr.login.dao.Permission',
				'role' = 'com.ncr.login.dao.Role'
			}
		},
		
		'defaultValues' = {
			'value' = '[NULL]',
			'created_date' = '[CURRENT_DATETIME]'
		},
		
		'requirements' = {
			'label' = { 'allowBlank' = false }
		},
		
		'preprocessors' = {}
	};
	
	public com.ncr.login.dao.Feature function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
}