component extends = 'com.ncr.abstract.ExceptionObject' {
	
	/*
		merge param flattens out result set
	*/
	
	// TODO 
	// implement bulk update
		
	public com.ncr.abstract.Gateway function init(config = {}) {
		variables.mapping = variables.model.getMapping();
		variables.properties = variables.model.getProperties();
		variables.metaData = getMetaData(variables.model);
		variables.recordPrototype = false;

		return this;
	}
	
	private struct function getFrom(param, options) {
		local.fromSqlArray = ['from `#variables.mapping.tableName#`'];
		local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
		local.exclude = ((structKeyExists(local.options, 'exclude')) ? local.options.exclude : []);
		local.result = {};
		
		if (structKeyExists(arguments.param, 'merge') && structKeyExists(variables.mapping, 'hasMany')) {
			local.merge = arguments.param.merge;
			local.mergeLen = arrayLen(local.merge);
			
			for (local.index = 1; local.index <= local.mergeLen; local.index++) {
				if (structKeyExists(variables.mapping.hasMany, local.merge[local.index])) {
					local.mergeModel = application.new(variables.mapping.hasMany[local.merge[local.index]].object);
					local.mergeModelMapping = local.mergeModel.getMapping();
					
					arrayAppend(local.fromSqlArray, 'left join `#local.mergeModelMapping.tableName#` on `#local.mergeModelMapping.tableName#`.`#variables.mapping.primaryKey#` = `#variables.mapping.tableName#`.`#variables.mapping.primaryKey#`');
				}
			}
		}
		
		if (structKeyExists(variables.mapping, 'manyToMany') && structKeyExists(local.options, 'loadMap')) {
		
			for (local.tableName in variables.mapping.manyToMany) {
				
				arrayAppend(local.fromSqlArray, "left join `#local.tableName#` on `#local.tableName#`.`#variables.mapping.primaryKey#` = `#variables.mapping.tableName#`.`#variables.mapping.primaryKey#`");			
				
				local.table = variables.mapping.manyToMany[local.tableName];
				
				for (local.objectName in local.table) {
					local.object = application.new(local.table[local.objectName]);
					local.mapping = local.object.getMapping();
					
					if (arrayFind(local.exclude, local.mapping.tableName)) {
						arrayDeleteAt(local.fromSqlArray, arrayLen(local.fromSqlArray));	
					}
					else {
						arrayAppend(local.fromSqlArray, "left join `#local.mapping.tableName#` on `#local.mapping.tableName#`.`#local.mapping.primaryKey#` = `#local.tableName#`.`#local.mapping.primaryKey#`");	
					}
				}
			}
		}
		
		if (structKeyExists(arguments.param, 'mapTo')) {
			arrayAppend(local.fromSqlArray, this.getMapToSql(arguments.param.mapTo));	
		}

		local.result.sql = arrayToList(local.fromSqlArray, ' ');
		
		return local.result;
	}
	
	public any function delete(param, options) {
		local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
		
		try {
			
			local.sql = "delete from `#variables.mapping.tableName#`";
			
			if (structKeyExists(arguments.param, 'where')) {
				local.sql &= ' where #arguments.param.where#';	
			}
			
			return application.query.run({
				datasource = application.dsn.default,
				sql = local.sql & ';'
			}).getResult();
		}
		catch (any e) {
			local.detail = { 'arguments' = arguments };
			return application.new('com.ncr.Exception', {
				level = 'error',
				label = 'com.ncr.abstract.Gateway.#variables.mapping.tableName#.delete',
				message = 'Try catch for delete.',
				detail = serializeJson(local.detail)
			});
		}
	}
	
	public any function queryBy(param, options, returnObject) {
		local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
		local.returnObject = ((structKeyExists(arguments, 'returnObject')) ? arguments.returnObject : false);
		
		try {
		
			if (!structKeyExists(arguments.param, 'from')) {
				local.fromObject = getFrom(arguments.param, local.options);
				local.from = local.fromObject.sql;
			}
			else {
				local.from = arguments.param.from;
			}
			
			if (structKeyExists(arguments.param, 'join')) {
				local.from &= ' #arguments.param.join#';	
			}
			
			if (structKeyExists(arguments.param, 'select')) {
				local.sql = 'select #arguments.param.select# #local.from#';
			}
			else {
				local.sql = 'select * #local.from#';	
			}
			
			if (structKeyExists(arguments.param, 'where')) {
				local.sql &= ' where #arguments.param.where#';	
			}
			
			if (structKeyExists(arguments.param, 'groupBy')) {
				local.sql &= ' group by #arguments.param.groupBy#';	
			}
			
			if (structKeyExists(arguments.param, 'orderBy')) {
				local.sql &= ' order by #arguments.param.orderBy#';	
			}
			
			if (structKeyExists(arguments.param, 'limit')) {
				local.sql &= ' limit #arguments.param.limit#';	
			}
			
			try {
				local.queryParam = {
					datasource = application.dsn.default,
					sql = local.sql & ' ;'
				};
				
				if (structKeyExists(arguments.param, 'params')) {
					local.queryParam.params = arguments.param.params;	
				}
				
				if (variables.mapping.tableName != 'log') {
					application.log.write({
						level = 'trace',
						label = 'com.ncr.abstract.Gateway.queryBy',
						message = 'Query run on Object #variables.mapping.tableName#'
					});	
				}
				
				local.object = application.query.run(local.queryParam);
				local.result = local.object.getResult();
			} catch(any e) {
				local.detail = { 'arguments' = arguments, 'exception' = e };
				return application.new('com.ncr.Exception', {
					level = 'error',
					label = 'com.ncr.abstract.Gateway.#variables.mapping.tableName#.queryBy',
					message = 'Try catch for query.run in queryBy.',
					detail = serializeJson(local.detail)
				});
			}

		}
		catch (any e) {
			local.detail = { 'arguments' = arguments };
			return application.new('com.ncr.Exception', {
				level = 'error',
				label = 'com.ncr.abstract.Gateway.#variables.mapping.tableName#.queryBy',
				message = 'Try catch for queryBy.',
				detail = serializeJson(local.detail)
			});
		}
		
		if (local.returnObject) {
			return {
				query = local.object,
				result = local.result
			};
		}
		else {
			return local.result;			
		}
	}
	
	public any function readBy(param, options) {
		local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
		local.options.totalCount = ((structKeyExists(local.options, 'totalCount')) ? local.options.totalCount : false);
		
		try {

			local.param = arguments.param;
			
			if (!structKeyExists(arguments.param, 'from')) {
				local.fromObject = getFrom(arguments.param, local.options);
				local.param.from = local.fromObject.sql;
			}
			else {
				local.param.from = arguments.param.from;
			}
			
			if (local.options.totalCount) {
				local.object = this.queryBy(local.param, local.options, true);
				local.query = local.object.query;
				local.result = local.object.result;
			}
			else {
				local.result = this.queryBy(local.param, local.options);	
			}
			
			local.resultLen = local.result.recordCount;
			local.columns = getMetaData(local.result);
			local.columnsLen = arrayLen(local.columns);
			local.array = [];
			local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
			local.options.include = ((structKeyExists(local.options, 'include')) ? local.options.include : []);
	
			for (local.index = 1; local.index <= local.resultLen; local.index++) {
				local.record = {};
				for (local.iindex = 1; local.iindex <= local.columnsLen; local.iindex++) {
					
					local.record[local.columns[local.iindex].name] = local.result[local.columns[local.iindex].name][local.index];
					
					if (!structKeyExists(local.param, 'merge') && structKeyExists(variables.mapping, 'hasMany')) {
						for (local.field in variables.mapping.hasMany) {
							if (!arrayFind(local.options.include, local.field)) { continue; }
							local.childrenParam = {
								mapping = variables.mapping,
								object = variables.mapping.hasMany[local.field],
								field = local.field,
								id = local.record[variables.mapping.primaryKey],
								include = local.options.include
							};
							local.record[lcase(listLast(variables.mapping.hasMany[local.field].object, '.')) & 's'] = readChildren(local.childrenParam);		
						}
					}
				}
				
				arrayAppend(local.array, local.record);
			}

		}
		catch (any e) {
			local.detail = { 'arguments' = arguments };
			return application.new('com.ncr.Exception', {
				level = 'error',
				label = 'com.ncr.abstract.Gateway.#variables.mapping.tableName#.readBy',
				message = 'Try catch for readBy.',
				detail = serializeJson(local.detail)
			});
		}

		if (structKeyExists(local.options, 'fields') && local.options.fields) {
			local.fields = this.getFields(local.result);
			
			local.sqlParts = { 
				select = ((structKeyExists(local.param, 'select')) ? local.param.select : ' * '), 
				from = local.param.from, 
				join = ((structKeyExists(local.param, 'join')) ? local.param.join : ''),
				where = ((structKeyExists(local.param, 'where')) ? ('where ' & local.param.where) : ''),
				groupBy = ((structKeyExists(local.param, 'groupBy')) ? ('group by ' & local.param.groupBy) : '')
			};
			
			local.array = {
				'success' = true,
				'fields' = local.fields,
				'rows' = local.array,
				'total' = ((local.options.totalCount) ? this.getTotalCount(local.sqlParts, ((structKeyExists(arguments.param, 'params')) ? arguments.param.params : '')) : local.result.recordCount)
			};	
			
			if (structKeyExists(local.options, 'debug')) {
				local.array.sql = local.sqlParts;
			}
		}

		return local.array;
	}
	
	public numeric function getTotalCount(query, params) {
		local.sql = ((len(trim(arguments.query.from))) ? arguments.query.from : arguments.query.join) & ' ' & arguments.query.where & ' ' & arguments.query.groupBy;
		local.queryParam = {
			datasource = application.dsn.default,
			sql = 'select ' & arguments.query.select & ' ' & local.sql & ' ;'
		};
		
		if (isStruct(arguments.params)) {
			local.queryParam.params = arguments.params;
		}
		
		local.result = application.query.run(local.queryParam).getResult();
		
		return local.result.recordCount;
	}

	private array function readChildren(param) {
		local.gatewayName = replace(arguments.param.object.object, '.dao.', '.gateway.');
		local.gateway = application.new(local.gatewayName);
		local.childModel = local.gateway.getModel();
		local.childMapping = local.childModel.getMapping();
		
		// TODO if this needs to map a manyToMany, we can just override the from parameter
		if (structKeyExists(local.childMapping, 'manyToMany')) {
			if (structKeyExists(arguments.param.mapping, 'manyToMany')) {
				local.objectMatch = structFindKey(arguments.param.mapping.manyToMany, arguments.param.field);
				if (arrayLen(local.objectMatch)) {
					local.pathArray = listToArray(local.objectMatch[1].path, '.');
					local.mapTable = local.pathArray[1];
					local.objectTable = local.pathArray[2];
					
					local.selectSql = "`#local.objectTable#`.*, `#arguments.param.mapping.tableName#`.`#arguments.param.mapping.primaryKey#`";
					local.fromSql = [
						"from `#local.mapTable#`",
						"left join `#local.objectTable#` on `#local.mapTable#`.`#local.childMapping.primaryKey#` = `#local.objectTable#`.`#local.childMapping.primaryKey#`",
						"left join `#arguments.param.mapping.tableName#` on `#local.mapTable#`.`#arguments.param.mapping.primaryKey#` = `#arguments.param.mapping.tableName#`.`#arguments.param.mapping.primaryKey#`"
					];
					
					return local.gateway.readBy({
						select = local.selectSql,
						from = arrayToList(local.fromSql, ' '),
						where = "`#arguments.param.mapping.tableName#`.`#arguments.param.mapping.primaryKey#` = #arguments.param.id#"
					}, { include = arguments.param.include });
				}
			}
		}
		
		return local.gateway.readBy({ where = "`#arguments.param.mapping.primaryKey#` = #arguments.param.id#" }, { include = arguments.param.include });
	}
	
	public com.ncr.util.Iterator function iterateReadBy(param, options) {
		local.result = ((structKeyExists(arguments, 'options')) ? (this.readBy(arguments.param, arguments.options)) : (this.readBy(arguments.param)));
		
		return application.new('com.ncr.util.Iterator', local.result);
	}
	
	public com.ncr.util.Iterator function iterateQueryBy(param, options) {
		local.result = ((structKeyExists(arguments, 'options')) ? (this.queryBy(arguments.param, arguments.options)) : (this.queryBy(arguments.param)));
		
		return application.new('com.ncr.util.Iterator', local.result);
	}
	
	public any function getModel() {
		return variables.model;
	}
	
	public any function getMapping() {
		return variables.mapping;
	}
	
	public any function getProperties() {
		return variables.properties;
	}
	
	public string function getMapToSql(objectArray) {
		local.objectArray = arguments.objectArray;
		local.objectArrayLen = arrayLen(local.objectArray);
		local.sqlArray = [];
		
		for (local.index = 1; local.index <= local.objectArrayLen; local.index++) {
			local.gateway = application.new(local.objectArray[local.index].gateway);
			local.gatewayMapping = local.gateway.getMapping();
			local.mapName = local.objectArray[local.index].map;
			
			if (!structKeyExists(local.gatewayMapping, 'manyToMany') || !structKeyExists(local.gatewayMapping.manyToMany, local.mapName)) { continue; }
			
			local.objectMap = local.gatewayMapping.manyToMany[local.mapName];
			
			arrayAppend(local.sqlArray, "left join `#local.mapName#` on `#local.gatewayMapping.tableName#`.`#local.gatewayMapping.primaryKey#` = `#local.mapName#`.`#local.gatewayMapping.primaryKey#`");
				
			for (local.objectName in local.objectMap) {
				local.objectModel = application.new(local.objectMap[local.objectName]);
				local.objectModelMapping = local.objectModel.getMapping();
				
				arrayAppend(local.sqlArray, "left join `#local.objectModelMapping.tableName#` on `#local.objectModelMapping.tableName#`.`#local.objectModelMapping.primaryKey#` = `#local.mapName#`.`#local.objectModelMapping.primaryKey#`");	
			}
		}
		
		return arrayToList(local.sqlArray, ' ');
	}
	
	public array function getFields(result) {			
		local.result = arguments.result;
		local.columns = getMetaData(local.result);
		local.columnsLen = arrayLen(local.columns);
		local.AbstractModel = application.new('com.ncr.abstract.Model');
		local.fields = [];
		
		for (local.index = 1; local.index <= local.columnsLen; local.index++) {
			local.javascriptType = local.AbstractModel.getJavascriptType(local.columns[local.index].typeName);
			
			arrayAppend(local.fields, {
				'name' = local.columns[local.index].name,
				'type' = local.javascriptType
			});
		}
		
		return local.fields;
	}

	public any function insert(logArray, options) {
		local.options = ((structKeyExists(arguments, 'options')) ? arguments.options : {});
		local.options.supressPreprocessors = ((structKeyExists(local.options, 'supressPreprocessors')) ? local.options.supressPreprocessors : false);
		
		try {
			
			local.mapping = this.getMapping();
			local.properties = this.getProperties();
			local.sqlArray = ['insert into `#local.mapping.tableName#`'];
			local.rowArray = [];
			local.idArray = [];
			
			local.logArray = arguments.logArray;
			local.logArrayLen = arrayLen(local.logArray);
			
			local.fieldArray = listToArray(structKeyList(local.logArray[1]));
			local.fieldArrayLen = arrayLen(local.fieldArray);
			local.fields = [];
			
			for (local.index = 1; local.index <= local.logArrayLen; local.index++) {
				local.valueArray = [];
				
				for (local.iindex = 1; local.iindex <= local.fieldArrayLen; local.iindex++) {
					local.fieldFilter = [local.mapping.primaryKey,'created_date','modified_last_date'];
					
					if (!arrayFind(local.fieldFilter, local.fieldArray[local.iindex])) {
						local.value = local.logArray[local.index][local.fieldArray[local.iindex]];
						
						if (structKeyExists(local.mapping, 'preprocessors') && 
							structKeyExists(local.mapping.preprocessors, local.fieldArray[local.iindex]) && 
							!local.options.supressPreprocessors) {
							
							local.model = this.getModel();
							local.processorArray = local.mapping.preprocessors[local.fieldArray[local.iindex]];
							local.processorArrayLen = arrayLen(local.processorArray);
							
							for (local.pindex = 1; local.pindex <= local.processorArrayLen; local.pindex++) {
								local.processorName = getMetaData(local.processorArray[local.pindex]).name;
								local.value = evaluate('this.getModel().#local.processorName#(local.value)'); 
 							}
						}
						
						local.typeFilter = ['numeric','boolean'];
						if (index == 1) { arrayAppend(local.fields, local.fieldArray[local.iindex]); }
						
						if (!arrayFind(typeFilter, local.properties[local.fieldArray[local.iindex]].type)) {
							local.value = "'" & local.value & "'";
						}
						arrayAppend(local.valueArray, local.value);
					}
				}
				arrayAppend(local.rowArray, '(' & arrayToList(local.valueArray) & ')');
			}
			
			arrayAppend(local.sqlArray, "(#listQualify(arrayToList(local.fields), '`')#)");
			arrayAppend(local.sqlArray, "values #arrayToList(local.rowArray)#;");
			
			local.result = application.query.run({
				datasource = application.dsn.default,
				sql = arrayToList(local.sqlArray, ' ')
			});
			
			return true;
		}
		catch (any e) {	
			local.exceptionParam = {
				level = 'error',
				label = 'com.ncr.abstract.Gateway.#variables.mapping.tableName#.bulkInsert',
				message = 'There was an error with this bulk insert.',
				detail = serializeJson(e)
			};
			return application.new('com.ncr.Exception', local.exceptionParam);
		}
	}

}