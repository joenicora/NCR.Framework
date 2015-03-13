component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	
	property type = 'numeric' name = 'entity_id';
	property type = 'numeric' name = 'parent_id';
	property type = 'string' name = 'title';
	property type = 'string' name = 'description';
	property type = 'string' name = 'website';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	property array user;
	property array userGroup;
	property array address;
	
	variables.mapping = {
		'name' = 'entity',
		'tableName' = 'entity',
		'primaryKey' = 'entity_id',
		
		'hasMany' = {
			'user' = {
				'object' = 'com.ncr.login.dao.User'
			},
			'address' = {
				'object' = 'com.ncr.login.dao.Address'
			}
		},

		'manyToMany' = {
			'entity_address_map' = {
				'address' = 'com.ncr.login.dao.Address'
			}
		},
		
		'defaultValues' = {
			'parent_id' = '[NULL]',
			'created_date' = '[CURRENT_DATETIME]'
		},
		
		'requirements' = {
			'title' = { 'allowBlank' = false }
		},
		
		'preprocessors' = {}
	};
	
	public com.ncr.login.dao.Entity function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
}