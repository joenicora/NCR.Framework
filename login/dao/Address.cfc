component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	property type = 'numeric' name = 'address_id';
	property type = 'string' name = 'label';
	property type = 'string' name = 'alias';
	property type = 'string' name = 'address1';
	property type = 'string' name = 'address2';
	property type = 'string' name = 'city';
	property type = 'string' name = 'statecode';
	property type = 'string' name = 'zipcode';
	property type = 'date' name = 'created_date';
	property type = 'date' name = 'modified_last_date';
	
	variables.mapping = {
		'name' = 'address',
		'tableName' = 'address',
		'primaryKey' = 'address_id',

		'manyToMany' = {
			'entity_address_map' = {
				'entity' = 'com.ncr.login.dao.Entity'
			}
		},
		
		'defaultValues' = {
			'alias' = '[NULL]',
			'address2' = '[NULL]',
			'created_date' = '[CURRENT_DATETIME]'
		},
		
		'requirements' = {
			'label' = { 'allowBlank' = false },
			'address1' = { 'allowBlank' = false },
			'city' = { 'allowBlank' = false },
			'statecode' = { 'allowBlank' = false },
			'zipcode' = { 'allowBlank' = false }
		},
		
		'preprocessors' = {}
	};
	
	public com.ncr.login.dao.Address function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
}