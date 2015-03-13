component {

	variables.config = {
		'fields' = [],
		'idProperty' = '',
		'associations' = []
	};

	public com.ncr.abstract.Model function init() {		
		return this;
	}
	
	public struct function getConfigStruct(required struct param) {
		if (!application.cache.has('com.ncr.abstract.Model.getConfigStruct_#arguments.param.model#')){
			local.modelArray = listToArray(arguments.param.model, ',');
			local.modelArrayLen = arrayLen(local.modelArray);
			local.configStruct = {};
			
			for (local.index = 1; local.index <= local.modelArrayLen; local.index++) {
				local.configStruct[local.modelArray[local.index]] = this.getConfig({ model = local.modelArray[local.index] });
			}		
			
			application.cache.set('com.ncr.abstract.Model.getConfigStruct_#arguments.param.model#', local.configStruct);
		}
		
		return application.cache.get('com.ncr.abstract.Model.getConfigStruct_#arguments.param.model#');
	}
	
	public struct function getConfig(required struct param) {
		local.model = application.new(arguments.param.model);
		local.mapping = local.model.getMapping();
		local.validator = local.model.getValidator();
		local.columnData = local.validator.getColumnData();
		local.properties = local.model.getProperties();
	
		variables.config.idProperty = local.mapping.primaryKey;
		
		for (local.field in local.columnData) {
			local.javascriptType = this.getJavascriptType(local.columnData[local.field].type);
			
			variables.config.fields.add({
				'name' = local.field,
				'type' = local.javascriptType,
				'isNullable' = local.columnData[local.field].isNullable,
				'maxLength' = local.columnData[local.field].columnSize
			});
		}
		
		if (structKeyExists(local.mapping, 'belongsTo')) {
			for (local.objectName in local.mapping.belongsTo) {
				local.objectShortName = local.mapping.belongsTo[local.objectName].object;
				
				variables.config.associations.add({
					'type' = 'belongsTo',
					'model' = local.objectShortName,
					'name' = lcase(listLast(local.objectShortName, '.')),
					'primaryKey' = local.mapping.belongsTo[local.objectName].id,
					'foreignKey' = variables.config.idProperty
				});
			}	
		}
		
		if (structKeyExists(local.mapping, 'hasMany')) {
			for (local.objectName in local.mapping.hasMany) {
				local.mappedModel = application.new(local.mapping.hasMany[local.objectName].object);
				local.objectShortName = getMetaData(local.mappedModel).fullName;
				
				variables.config.associations.add({
					'type' = 'hasMany',
					'model' = local.objectShortName,
					'name' = lcase(listLast(local.objectShortName, '.')),
					'associationKey' = lcase(listLast(local.objectShortName, '.')),
					'primaryKey' = local.mappedModel.getMapping().primaryKey
				});
			}	
		}
		
		return variables.config;
	}
	
	public string function getJavascriptType(required string type) {
		local.javascriptType = '';
		
		switch (arguments.type) {
			case 'int' :
				// local.javascriptType = 'int';
				local.javascriptType = 'numeric';
				break;			
			
			case 'boolean' :
				// local.javascriptType = 'boolean';
				local.javascriptType = 'string';
				break;
			
			case 'float' :
			case 'decimal' :
				// local.javascriptType = 'float';
				local.javascriptType = 'numeric';
				break;
			
			case 'timestamp' : 
			case 'datetime' : 
			case 'date' :
				// local.javascriptType = 'date';
				local.javascriptType = 'string';
				break;
				
			default : // string
				local.javascriptType = 'string';
				break;
		}
		
		return local.javascriptType;
	}
}