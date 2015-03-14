component extends = 'com.ncr.abstract.ExceptionObject' {

	/*
		DAO is only for single object access, use gateways for multiples
	*/

	// TODO 
	// add deactivated_date to all objects, this denotes a deleted item in the system
	// dates are not formatted properly in JSON
	// there are no query params used with manyTomany inserts, fix this
	
	variables.mapping = {};
	variables.metaData = {};
	variables.map = {};

	public com.ncr.abstract.dao function init(struct config = {}) {
		super.init();
		
		local.metaData = getMetaData(this);
		
		if (!structKeyExists(local.metaData, 'properties')) {
			local.metaData = structFindKey(local.metaData, 'properties')[1].owner;
		}
		
		variables.metaData = local.metaData;
		variables.properties = {};
		
		this.clearStruct();
		
		local.properties = variables.metaData.properties;

		for (local.index = 1; local.index <= arrayLen(local.properties); local.index++) {
			variables.properties[local.properties[local.index].name] = local.properties[local.index];
		}
		
		if (!application.cache.has('com.ncr.abstract.Dao_#variables.mapping.tableName#')) {	
			variables.validator = new com.ncr.abstract.Validator({
				datasource = application.dsn.default,
				table = variables.mapping.tableName,
				model = this
			});	
			application.cache.set('com.ncr.abstract.Dao_#variables.mapping.tableName#', variables.validator);
		}
		else {
			variables.validator = application.cache.get('com.ncr.abstract.Dao_#variables.mapping.tableName#');
		}
		
		if (structKeyExists(arguments.config, 'id')) {
			this.load(arguments.config.id);
		}
		else {
			this.setStruct(arguments.config);
		}

		return this;	
	}
	
	public numeric function getPrimaryKeyId() {
		local.getter = this['get' & variables.mapping.primaryKey];
		return local.getter();
	}
	
	public struct function getMapping() {
		return variables.mapping;
	}
	public struct function getProperties() {
		return variables.properties;
	}
	public struct function getValidator() {
		return variables.validator;
	}
	public struct function getMetaData() {
		return variables.metaData;
	}
	
	public struct function formatValue(field, value) {
		local.meta = this.getFieldMeta(arguments.field);
		local.value = arguments.value;
		
		switch  (local.meta.type) {
			case 'numeric' :
			case 'int' :
			case 'integer' :
				local.valueObject = {
					value = local.value,
					cftype = 'CF_SQL_NUMERIC'
				};
				break;
				
			case 'boolean' :
				local.valueObject = {
					value = local.value,
					cftype = 'CF_SQL_BIT'
				};
				break;
				
			case 'date' :
			case 'datetime' :
			case 'timestamp' :
				local.valueObject = {
					value = local.value,
					cftype = 'CF_SQL_TIMESTAMP'
				};
				break;
				
			case 'money' :
				local.valueObject = {
					value = local.value,
					cftype = 'CF_SQL_MONEY'
				};
				break;
				
			default :
				local.valueObject = {
					value = local.value,
					cftype = 'CF_SQL_CHAR'
				};
				break;
		}		

		if (structKeyExists(variables.mapping.defaultValues, field)) {
			if (!len(trim(value))) {
				if (variables.mapping.defaultValues[field] == '[CURRENT_DATETIME]') { 
					local.valueObject = {
						value = application.date.getDateTime(),
						cftype = 'CF_SQL_DATE'
					}; 
				}
				if (variables.mapping.defaultValues[field] == '[NULL]') {
					local.valueObject = {
						cftype = 'NULL'
					}; 
				}
				if (variables.mapping.defaultValues[field] == '[FALSE]') {
					local.valueObject = {
						value = 0,
						cftype = 'CF_SQL_BOOLEAN'
					}; 
				}
				if (variables.mapping.defaultValues[field] == '[TRUE]') {
					local.valueObject = {
						value = 1,
						cftype = 'CF_SQL_BOOLEAN'
					}; 
				}
				if (variables.mapping.defaultValues[field] == '[EMPTY_STRING]') {
					local.valueObject = {
						value = '',
						cftype = 'CF_SQL_CHAR'
					}; 
				}
			}
		}
		
		return local.valueObject;
	}
	
	public struct function getInsertSql() {
		local.struct = this.getStruct();
		local.fieldArray = [];		
		local.valueArray = [];		
		local.result = { sql = '', params = {} };
		
		for (local.key in local.struct) {
			
			if (!isSimpleValue(local.struct[local.key])) { continue; }
			if (!len(trim(local.struct[local.key]))) { continue; }
			
			arrayAppend(local.fieldArray, ' `#local.key#` ');
			arrayAppend(local.valueArray, ' :#local.key# ');
			
			local.result.params[local.key] = this.formatValue(local.key, local.struct[local.key]);
		}
	
		if (structKeyExists(variables.properties, 'created_date')) {
			local.dateTime = application.date.getDateTime();
			this.setCreated_date(local.dateTime);
			arrayAppend(local.fieldArray, ' `created_date` ');
			arrayAppend(local.valueArray, ' :created_date ');
			local.result.params['created_date'] = this.formatValue('created_date', local.dateTime);
		}
		
		local.result.sql = 'insert into `#variables.mapping.tableName#` (#arrayToList(local.fieldArray)#) values (#arrayToList(local.valueArray)#) ;';

		return local.result;
	}
	
	public struct function getUpdateSql() {
		local.struct = this.getStruct();
		local.setArray = [];
		local.result = { sql = '', params = {} };
		
		for (local.key in local.struct) {
			
			if (!isSimpleValue(local.struct[local.key])) { continue; }
			
			if (!len(trim(local.struct[local.key])) || local.key == 'modified_last_date') { continue; }
		
			arrayAppend(local.setArray, ' `#local.key#` = :#local.key# ');	
			local.result.params[local.key] = this.formatValue(local.key, local.struct[local.key]);
		}
		
		if (structKeyExists(variables.properties, 'modified_last_date')) {
			local.dateTime = this.formatValue("modified_last_date", application.date.getDateTime());
			this.setModified_last_date(local.dateTime.value);
			arrayAppend(local.setArray, ' `modified_last_date` = :modified_last_date ');
			local.result.params['modified_last_date'] = local.dateTime;
		}
		
		local.result.sql = 'update `#variables.mapping.tableName#` set #arrayToList(local.setArray)# where `#variables.mapping.primaryKey#` = #local.struct[variables.mapping.primaryKey]# ;';
		
		return local.result;
	}
	
	public struct function getDeleteSql() {
		local.struct = this.getStruct();
		local.result = {
			sql = 'delete from `#variables.mapping.tableName#` where `#variables.mapping.primaryKey#` = :#variables.mapping.primaryKey# ;',
			params = {}
		};
		local.result.params[variables.mapping.primaryKey] = this.formatValue(variables.mapping.primaryKey, local.struct[variables.mapping.primaryKey]);
		
		return local.result;
	}
	
	public any function save() {	
		
		try {
			local.struct = this.getStruct();
			local.isInsert = !structKeyExists(local.struct, variables.mapping.primaryKey);
			
			this.clearExceptions();
	
			if (structKeyExists(variables.mapping, 'requirements')) {
				for (local.field in variables.mapping.requirements) {
					
					// allowBlank
					if (structKeyExists(variables.mapping.requirements[local.field], 'allowBlank') && !variables.mapping.requirements[local.field].allowBlank) {
						if (!structKeyExists(local.struct, local.field) && local.isInsert) {
							this.getRoot().addException({
								level = 'error',
								label = 'required.validation.error',
								message = '#local.field# is a required field.',
								data = {
									field = local.field
								}
							});					
						}
					}
					
					// minLength
					if (structKeyExists(variables.mapping.requirements[local.field], 'minLength')) {
						
						if (!local.isInsert && !structKeyExists(local.struct, local.field)) { continue; }
						
						if (len(local.struct[local.field]) < variables.mapping.requirements[local.field].minLength) {
							this.getRoot().addException({
								level = 'error',
								label = 'required.validation.error',
								message = '#local.field# needs to be at least #variables.mapping.requirements[local.field].minLength# characters long.',
								data = {
									field = local.field
								}
							});					
						}
					}
					
				}	
			}		
			
			if (structKeyExists(variables.mapping, 'preprocessors')) {
				for (local.field in variables.mapping.preprocessors) {
					local.preprocessors = variables.mapping.preprocessors[local.field];
					local.preprocessorsLen = arrayLen(local.preprocessors);
					local.setter = this['set' & local.field];
					
					for (local.index = 1; local.index <= local.preprocessorsLen; local.index++) {
						local.struct = this.getStruct();
						local.preprocessor = local.preprocessors[local.index];
						
						if (!structKeyExists(local.struct, local.field)) { continue; }
						
						local.value = local.preprocessor(local.struct[local.field]);
						
						if (getMetaData(local.value).name == 'com.ncr.Exception') {
							this.getRoot().addException(local.value);
						}
						else {
							local.setter(local.value);	
						}
					}
				}
			}
			
			local.errorMessages = variables.validator.validateRecord(this.getStruct(), local.isInsert);
			local.errorMessagesLen = arrayLen(local.errorMessages);
			
			if (local.errorMessagesLen) {
				for (local.index = 1; local.index <= local.errorMessagesLen; local.index++) {
					this.getRoot().addException({
						label = 'field.validation.error #getMetaData(this).name#',
						message = local.errorMessages[local.index].message,
						data = local.errorMessages[local.index]
					});	
				}
			}
			
			if (arrayLen(this.getRoot().getExceptions())) {
				return this;
			}
			
			if (!local.isInsert) {
				local.sql = this.getUpdateSql();
			}
			else {
				local.sql = this.getInsertSql();
			}
			
			lock scope = 'application' type = 'exlusive' timeout = '10' {
				
				transaction {
				
				application.query.run({
					datasource = application.dsn.default,
					sql = local.sql.sql,
					params = local.sql.params
				});
				
				if (local.isInsert) {
					local.result = application.query.run({
						datasource = application.dsn.default,
						sql = 'select last_insert_id() as lastId from `#variables.mapping.tableName#` limit 1;'
					}).getResult();
					local.setter = this['set' & variables.mapping.primaryKey];
					local.setter(local.result['lastId'][1]);
				}
				
				local.map = ((structKeyExists(variables.mapping, 'manyToMany')) ? variables.mapping.manyToMany : {});
				
				if (structKeyExists(variables.mapping, 'manyToMany') && !structIsEmpty(local.map)) {					
					for (local.tableName in variables.mapping.manyToMany) {
						if (structKeyExists(local.map, local.tableName)) {
							
							local.objectFields = {};
							local.objectFields[variables.mapping.primaryKey] = [];
							local.mappedArrayLen = 0;
							
							for (local.objectName in local.map[local.tableName]) {
								local.objectModel = application.new(variables.mapping.manyToMany[local.tableName][local.objectName]);
								
								local.objectMapping = local.objectModel.getMapping();
								
								local.objectFields[local.objectMapping.primaryKey] = [];
								
								local.mappedGetter = this['get' & local.objectName];
								local.mappedArray = local.mappedGetter();
								
								if (!structKeyExists(local, 'mappedArray')) { continue; }
								
								local.mappedArrayLen = arrayLen(local.mappedArray);
								
								//local.valueArray = local.map[local.tableName][local.objectName];
								//local.valueArrayLen = arrayLen(local.valueArray);
								
								for (local.index = 1; local.index <= local.mappedArrayLen; local.index++) {
									local.mappedValue = mappedArray[local.index][local.objectMapping.primaryKey];
									arrayAppend(local.objectFields[local.objectMapping.primaryKey], local.mappedValue);
									
									if (arrayLen(local.objectFields[variables.mapping.primaryKey]) <= local.mappedArrayLen) {
										arrayAppend(local.objectFields[variables.mapping.primaryKey], this.getPrimaryKeyId());			
									}
								}
							}
							
							if (!local.mappedArrayLen) { continue; } // nothing to update
							
							local.rowArray = [];
							for (local.index = 1; local.index <= local.mappedArrayLen; local.index++) {
								arrayAppend(local.rowArray, []);
								for (local.field in local.objectFields) {
									arrayAppend(local.rowArray[local.index], local.objectFields[local.field][local.index]);
								}
								local.rowArray[local.index] = '(' & arrayToList(local.rowArray[local.index]) & ')';
							}	
							
							local.objectSql = 'insert into `#local.tableName#` (#listQualify(structKeyList(local.objectFields), '`')#) values #arrayToList(local.rowArray)# ;';
								application.query.run({
								datasource = application.dsn.default,
								sql = 'delete from `#local.tableName#` where `#variables.mapping.primaryKey#` = #this.getPrimaryKeyId()#;'
							}).getResult();
							
							application.query.run({
								datasource = application.dsn.default,
								sql = local.objectSql
							}).getResult();
						}
					}
				}

				if (structKeyExists(variables.mapping, 'hasMany')) {
					for (local.field in variables.mapping.hasMany) {
					
						if (arrayLen(structFindKey(variables.mapping.manyToMany, local.field))) { continue; } // this is a manyToMany
					
						local.struct = this.getStruct();
						if (structKeyExists(local.struct, local.field)) {
							local.objectArray = local.struct[local.field];
							local.objectArrayLen = arrayLen(local.objectArray);
							
							for (local.index = 1; local.index <= local.objectArrayLen; local.index++) {
								local.innerObject = local.objectArray[local.index];
								
								if (isStruct(local.innerObject)) {
									local.innerObject = application.new(variables.mapping.hasMany[local.field].object, local.innerObject);
									local.getter = this['get' & local.field];
									local.contextArray = local.getter();
									arrayInsertAt(local.contextArray, local.index, local.innerObject);
									arrayDeleteAt(local.contextArray, local.index + 1);
									local.setter = this['set' & local.field];
									local.setter(local.contextArray);
								}
								
								// evaluate('local.innerObject.set' & variables.mapping.primaryKey & '(local.struct[variables.mapping.primaryKey])');
								invoke(local.innerObject, 'set#variables.mapping.primaryKey#', local.struct[variables.mapping.primaryKey]);

								local.innerObject._superClass = this;
								local.innerObject.save();

								if (arrayLen(this.getRoot().getExceptions())) {
									transactionRollback();
									return this;
								}
							}
						}
					}
				} // end if
				
				} // end transaction
				
			} // end lock

			application.log.write({
				'level' = 'trace',
				'label' = 'com.ncr.login.dao.save',
				'message' = 'Object #variables.mapping.tableName# saved (#this.getPrimaryKeyId()#).'
			});
		}
		catch (any e) {
			local.detail = { 'arguments' = arguments, exception = e };

			this.getRoot().addException({
				label = 'com.ncr.abstract.Dao.#variables.mapping.tableName#.save',
				message = 'Try catch for save method.',
				detail = serializeJson(local.detail)
			});
		}
		
		return this;
	}
	
	public any function add(param) {
		for (local.object in arguments.param) {
			if (structKeyExists(variables.mapping.hasMany, local.object)) {
				local.setter = this['set' & local.object];
				
				local.objectArray = arguments.param[local.object];
				local.obejctArrayLen = arrayLen(local.objectArray);
				local.newObjectArray = [];
				
				for (local.index = 1; local.index <= local.obejctArrayLen; local.index++) {
					arrayAppend(local.newObjectArray, application.new(variables.mapping.hasMany[local.object].object, local.objectArray[local.index]));	
				}
				local.setter(newObjectArray);
			}	
		}
		
		return this;
	}
	
	public array function getChildrenBy(child) {
		if (structKeyExists(variables.mapping, 'hasMany')) {
			if (structKeyExists(variables.mapping.hasMany, arguments.child)) {
				local.getter = this['get' & arguments.child];
				return ((isArray(local.getter())) ? local.getter() : []);
			}
		}
		
		return [];
	}
	
	public any function delete() {	
	
		try {
			local.sql = this.getDeleteSql();
				
			local.result = application.query.run({
				datasource = application.dsn.default,
				sql = local.sql.sql,
				params = local.sql.params
			});

			application.log.write({
				'level' = 'trace',
				'label' = 'com.ncr.login.dao.delete',
				'message' = 'Object #variables.mapping.tableName# deleted (#this.getPrimaryKeyId()#).'
			});
		}
		catch (any e) {
			local.detail = { 'arguments' = arguments, struct = this.getStruct() };

			this.getRoot().addException({
				label = 'com.ncr.abstract.Dao.#variables.mapping.tableName#.delete',
				message = 'Try catch for delete.',
				detail = serializeJson(local.detail)
			});
		}
	}
	
	public any function load(id, options) {
		
		try {
			this.clearStruct();
				
			local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
			local.options.include = ((structKeyExists(local.options, 'include')) ? local.options.include : []);
			local.record = { id = arguments.id };
			local.query = application.query.run({
				datasource = application.dsn.default,
				sql = 'select * from #variables.mapping.tableName# where #variables.mapping.primaryKey# = #record.id#'
			});
			
			local.record = local.query.getResult();
			
			if (local.record.recordCount == 0) {
				this.getRoot().addException({
					label = 'load.error',
					message = 'This record does not exist'
				});
				return this;
			}
			
			local.columns = getMetaData(local.record);
			
			for (local.index = 1; local.index <= arrayLen(local.columns); local.index++) {
				local.setter = this['set' & local.columns[local.index].name];
				local.value = local.record[local.columns[local.index].name][1];
				
				if (len(local.value)) {
					local.setter(local.value);	
				}
			}
			
			if (structKeyExists(variables.mapping, 'belongsTo')) {	
				
				for (local.objectName in variables.mapping.belongsTo) {		
				
					if (!arrayFind(local.options.include, local.objectName)) { continue; }
								
					local.setter = this['set' & local.objectName];
					local.object = application.new(variables.mapping.belongsTo[local.objectName].object);
					
					local.object._superClass = this;
					
					local.object.load(this.getStruct()[variables.mapping.belongsTo[local.objectName].id]);
					local.setter(local.object);
					
					if (structKeyExists(local.object.getMapping(), 'hasMany')) {	
						structDelete(local.object.getMapping().hasMany, this.getMapping().name);
						
						for(local.parentChild in local.object.getMapping().hasMany) {
							local.childSetter = local.object['set' & local.parentChild];
							local.childSetter(this.queryChildren(local.object, local.object.getMapping(), local.options, local.object.getPrimaryKeyId()));
						}
					}
					
					
				}
			}
			
			if (structKeyExists(variables.mapping, 'hasMany')) {	
				local.objectArray = this.queryChildren(this, variables.mapping, local.options, arguments.id);
			}
			
			if (structKeyExists(variables.mapping, 'manyToMany') && structKeyExists(local.options, 'loadMap') && local.options.loadMap) {
				this.setMap(this.buildMap(local.options));
			}

			application.log.write({
				'level' = 'trace',
				'label' = 'com.ncr.login.dao.load',
				'message' = 'Object #variables.mapping.tableName# loaded (#this.getPrimaryKeyId()#).'
			});
		}
		catch (any e) {
			local.detail = { 'arguments' = arguments, error = e };

			this.getRoot().addException({
				label = 'com.ncr.abstract.Dao.#variables.mapping.tableName#.load',
				message = 'Try catch for load.',
				detail = serializeJson(local.detail)
			});
		}
		
		return this;
	}
	
	public array function queryChildren(context, mapping, options, id) {
		local.mapping = arguments.mapping;
		local.options = arguments.options;		
		local.context = arguments.context;	
		local.contextMapping = local.context.getMapping();
		local.objectArray = [];
					
		for (local.object in local.mapping.hasMany) {

			if (!arrayFind(local.options.include, local.object)) { continue; }
		
			local.gatewayName = replace(local.mapping.hasMany[local.object].object, '.dao.', '.gateway.');
			local.manyToManyMap = ((structKeyExists(local.contextMapping, 'manyToMany')) ? structFindKey(local.contextMapping.manyToMany, local.object) : []);
			
			if (arrayLen(local.manyToManyMap) > 0) {
				local.objectArray = listToArray(local.manyToManyMap[1].path, '.');	
				local.objectModel = application.new(local.manyToManyMap[1].value);
				local.objectModelMapping = local.objectModel.getMapping();
				
				local.mapSql = [
					"select `#local.objectArray[2]#`.* from `#local.objectArray[1]#`",
					"join `#local.objectArray[2]#` on `#local.objectArray[1]#`.`#local.objectModelMapping.primaryKey#` = `#local.objectArray[2]#`.`#local.objectModelMapping.primaryKey#`",
					"where `#local.objectArray[1]#`.`#local.mapping.primaryKey#` = #arguments.id#"
				];
				
				local.children = application.query.run({
					datasource = application.dsn.default,
					sql = arrayToList(local.mapSql, ' ')
				});
				
				local.children = application.query.toArray(local.children.getResult());
			}
			else {			
				local.gateway = application.new(local.gatewayName);
				local.gatewayModel = local.gateway.getModel();
		
				local.children = local.gateway.readBy(
					{
						where = '#local.mapping.primaryKey# = #arguments.id#'
					}
				);	
			}
			
			local.objectArray = [];
			local.childrenLen = arrayLen(local.children);
			
			for (local.index = 1; local.index <= local.childrenLen; local.index++) {
				
				local.newContext = application.new(local.mapping.hasMany[local.object].object, local.children[local.index]);
			
				local.newContext._superClass = this;
				
				arrayAppend(local.objectArray, local.newContext);
				
				local.childMapping = local.newContext.getMapping();				
				local.childId = local.newContext.getPrimaryKeyId();				
					
				if (structKeyExists(local.childMapping, 'hasMany')) {
					this.queryChildren(local.newContext, local.childMapping, local.options, local.childId);	
				}
				
				if (structKeyExists(local.childMapping, 'belongsTo')) {
					structDelete(local.childMapping.belongsTo, local.mapping.name, true);
					
					for (local.parentObject in local.childMapping.belongsTo) {
						for (local.iindex = 1; local.iindex <= arrayLen(local.objectArray); local.iindex++) {
							local.setter = local.objectArray[local.iindex]['set' & local.parentObject];
							local.parentContext = application.new(local.childMapping.belongsTo[local.parentObject].object);
							
							local.parentContext._superClass = local.context;
							
							local.parentContext.load(local.newContext.getPrimaryKeyId());
							local.setter(local.parentContext);
						}
					}
				}


			}
			
			// evaluate('local.context.set' & local.object & '(local.objectArray)');
			invoke(local.context, 'set#local.object#', local.objectArray);
		}
		
		return local.objectArray;
	}
	
	public struct function buildMap(options) {
		local.map = {};
		local.options = arguments.options;
		local.options.exclude = ((structKeyExists(local.options, 'exclude')) ? local.options.exclude : []);
		
		for (local.table in variables.mapping.manyToMany) {
			
			if (arrayFind(local.options.exclude, local.table)) { continue; }
			
			local.map[local.table] = {};
			local.model = {};
			
			local.sqlArray = ['select * from'];
			
			local.tableObject = variables.mapping.manyToMany[local.table];			
			
			arrayAppend(local.sqlArray, '`#local.table#` join `#variables.mapping.tableName#` on `#variables.mapping.tableName#`.`#variables.mapping.primaryKey#` = `#local.table#`.`#variables.mapping.primaryKey#`');
			
			for (local.object in local.tableObject) {
				local.model[local.object] = application.new(local.tableObject[local.object]);
				local.mapping = local.model[local.object].getMapping();
				
				local.map[local.table][local.mapping.tableName] = [];
				
				arrayAppend(local.sqlArray, "join `#local.mapping.tableName#` on `#local.mapping.tableName#`.`#local.mapping.primaryKey#` = `#local.table#`.`#local.mapping.primaryKey#`");
			}
			
			arrayAppend(local.sqlArray, "where `#variables.mapping.tableName#`.`#variables.mapping.primaryKey#` = #this.getPrimaryKeyId()#");
			
			local.result = application.query.run({ datasource = application.dsn.default, sql = arrayToList(local.sqlArray, ' ') }).getResult();
			
			for (local.object in local.model) {
				local.mapping = local.model[local.object].getMapping();
				local.valueList = application.query.getValueList(local.result, local.mapping.primaryKey);
				local.map[local.table][local.object] = local.valueList;
			}
		}
		
		return local.map;
	}
	
	public struct function getFieldMeta(fieldName) {
		local.properties = variables.metaData.properties;

		for (local.index = 1; local.index <= arrayLen(local.properties); local.index++) {
			if (local.properties[local.index].name == fieldName) {
				return local.properties[local.index];
			}
		}
		
		return {};
	}
	
	public struct function getStruct(properties, scope) {
		lock scope = 'application' type = 'exlusive' timeout = '10' {
		
			local.properties = ((structKeyExists(arguments, 'properties')) ? arguments.properties : variables.metaData.properties);
			local.scope = ((structKeyExists(arguments, 'scope')) ? arguments.scope : this);
			local.struct = ((structKeyExists(arguments, 'struct')) ? arguments.struct : {});
			
			for (local.index = 1; local.index <= arrayLen(local.properties); local.index++) {
				// local.getterValue = evaluate('local.scope.get' & local.properties[local.index].name & '()');
				local.getterValue = invoke(local.scope, 'get#local.properties[local.index].name#');
				
				if (!isNull(local.getterValue)) {
					if (!isSimpleValue(local.getterValue)) {
						local.metaData = getMetaData(local.getterValue);
						
						if (structKeyExists(local.metaData, 'type') && local.metaData.type == 'component') {		
							local.struct[local.properties[local.index].name] = local.getterValue.getStruct();
						}
						
						if (isArray(local.getterValue)) {
							local.childArray = [];
							
							for (local.iindex = 1; local.iindex <= arrayLen(local.getterValue); local.iindex++) {
								
								if (
									structKeyExists(local.getterValue[iindex], 'getMetaData') && 
									structKeyExists(local.getterValue[iindex].getMetaData(), 'type') && 
									local.getterValue[iindex].getMetaData().type == 'component'
								) {
									
									arrayAppend(
										local.childArray, 
										this.getStruct(getMetaData(local.getterValue[iindex]).properties, local.getterValue[iindex])
									);
								}
								else {
									arrayAppend(
										local.childArray, 
										local.getterValue[iindex]
									);
								}
								
							}
							local.struct[local.properties[local.index].name] = local.childArray;
						}
					}
					else {
						local.struct[local.properties[local.index].name] = local.getterValue;	
					}
				}
			}
			
			if (!structIsEmpty(this.getMap())) {
				local.struct['map'] = this.getMap();
			}
		}
		
		return local.struct;
	}

	public struct function setStruct(values) {
		lock scope = 'application' type = 'exlusive' timeout = '10' {
		
			local.properties = variables.metaData.properties;
			
			for (local.index = 1; local.index <= arrayLen(local.properties); local.index++) {
			
				if (structKeyExists(arguments.values, local.properties[local.index].name)) {
					if (isStruct(arguments.values[local.properties[local.index].name])) {
						local.object = application.new(structFindValue(variables.metaData, local.properties[local.index].name)[1].owner.type);
						local.object.setStruct(arguments.values[local.properties[local.index].name]);
						local.setter = this['set' & local.properties[local.index].name];
						local.setter(local.object);
					}
					else {
					
						try{
							local.setter = this['set' & local.properties[local.index].name];
							local.setter(arguments.values[local.properties[local.index].name]);
						}
						catch(any e) {
							// TODO: this is dangerous, we should write to the log when there is a type mismatch error
							local.setter(javaCast('null', 0));
						}
					
					}
					
				}
			}
			
			if (structKeyExists(arguments.values, 'map')) {
				this.setMap(arguments.values.map);
			}
		}
		
		return this;
	}
	
	public void function clearStruct() {
		local.properties = variables.metaData.properties;
		
		for (local.index = 1; local.index <= arrayLen(local.properties); local.index++) {
			local.setter = this['set' & local.properties[local.index].name];
			local.setter(javaCast('null', 0));
		}
		
		this.setMap({});		
	}
	
	public any function getParent(objectName) {
		if (!structKeyExists(variables.mapping, 'belongsTo')) {
			return false;
		}
		
		if (structKeyExists(variables.mapping.belongsTo, arguments.objectName)) {
			local.struct = this.getStruct();
			local.parent = application.new(variables.mapping.belongsTo[arguments.objectName].object);
			local.parentMapping = local.parent.getMapping();
			local.foreignKeyId = local.struct[local.parentMapping.primaryKey];
			local.parent.load(local.foreignKeyId);

			return local.parent;
		}
		
		return false;
	}
	
	public any function getRoot(currentClass) {
		local.currentClass = ((structKeyExists(arguments, 'currentClass')) ? arguments.currentClass : this);
	
		if (!structKeyExists(local.currentClass, '_superClass')) {
			return local.currentClass;
		}
		else {
			return this.getRoot(local.currentClass._superClass);
		}
	}	
	
	public void function setMap(struct) {
		variables.map = arguments.struct;
	}
	
	public struct function getMap() {
		return variables.map;
	}
}