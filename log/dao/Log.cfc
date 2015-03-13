component accessors = 'true' extends = 'com.ncr.abstract.Dao' {
	property type = 'numeric' name = 'log_id';
	property type = 'numeric' name = 'level';
	property type = 'string' name = 'label';
	property type = 'string' name = 'message';
	property type = 'string' name = 'detail';
	property type = 'date' name = 'created_date';
	
	variables.mapping = {
		'tableName' = 'log',
		'primaryKey' = 'log_id',
		
		'defaultValues' = {
			'detail' = '[NULL]',
			'created_date' = '[CURRENT_DATETIME]'
		},
		
		'requirements' = {
			'level' = { 'allowBlank' = false },
			'label' = { 'allowBlank' = false }
		},
		
		'preprocessors' = {
			'detail' = [
				this.writeDetail
			],
			'level' = [
				this.parseLevel
			]
		}
	};
	
	public com.ncr.log.dao.Log function init(struct config = {}) {
		super.init(config);
		
		return this;
	}
	
	public any function save(required any logArray) {
		
		try {

			local.fields = [
				'level',
				'label',
				'message',
				'detail'
			];
			
			local.sqlArray = ['insert into `log`'];
			local.rowArray = [];
			
			local.logArray = ((isArray(arguments.logArray)) ? arguments.logArray : [arguments.logArray]);
			local.logArrayLen = arrayLen(local.logArray);
			
			for (local.index = 1; local.index <= local.logArrayLen; local.index++) {
				local.record = local.logArray[local.index];
				local.level = this.parseLevel((structKeyExists(local.record, 'level') ? local.record['level'] : 'error'));
				
				if (local.level <= application.logConfig.recordLevel) {
					local.record['detail'] = ((structKeyExists(local.record, 'detail')) ? local.record['detail'] : '');
					
					local.valueArray = [
						"'" & local.level & "'",
						"'" & left(local.record['label'], 255) & "'",
						"'" & left(local.record['message'], 255) & "'",
						"'" & ((len(trim(local.record['detail']))) ? this.writeDetail(local.record['detail']) : '') & "'"
					];
	
					arrayAppend(local.rowArray, '(' & arrayToList(local.valueArray) & ')');
				
				}
			}
			
			if (!arrayLen(local.rowArray)) {
				return true;
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
			this.save({
				level = 'error',
				label = 'com.ncr.log.dao.Log.save',
				message = 'Error writing log',
				detail = serializeJson(local)
			});
		}

		return this;
	}
	
	public string function writeDetail(value) {
		if (len(trim(arguments.value))) {
			local.fileName = 'log_' & createUUID() & '.txt';
			local.filePath = application.path.absolute.log & local.fileName;
	
			fileWrite(local.filePath, value);

			return local.fileName;
		}
		else {
			return arguments.value;
		}
	}
	
	public any function parseLevel(value) {
		if (!isNumeric(arguments.value)) {
			local.map = { 'error' = 0, 'warning' = 1, 'debug' = 2, 'info' = 3, 'trace' = 4 };
			return local.map[arguments.value];
		}
		else { return arguments.value; }
	}
}