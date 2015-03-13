component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	
	property type = 'numeric' name = 'user_group_id';
	property type = 'string' name = 'label';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	property array user;
	
	variables.mapping = {
		'name' = 'userGroup',
		'tableName' = 'user_group',
		'primaryKey' = 'user_group_id',

		'hasMany' = {
			'user' = {
				'object' = 'com.ncr.login.dao.User'
			}
		},
		
		'requirements' = {
			'label' = { 'allowBlank' = false }
		},
		
		'defaultValues' = {
			'entity_id' = '[NULL]',
			'created_date' = '[CURRENT_DATETIME]'
		},
		
		'preprocessors' = {}
	};
	
	public com.ncr.login.dao.UserGroup function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
}