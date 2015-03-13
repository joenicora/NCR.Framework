component {
	variables.dbinfo = {};
	
	public com.ncr.abstract.Validator function init(struct config = {}) {
		variables.dbinfo = new com.ncr.wrapper.Dbinfo();

		variables.model = arguments.config.model;
		
		local.columnData = variables.dbinfo.getContext({
			type = 'columns',
		    datasource = arguments.config.datasource,
		    table = arguments.config.table
		});
		
		variables.columnArray = [];
		
		local.columnDataLen = local.columnData.recordCount;
		
		variables.columnData = {};
		
		for (local.index = 1; local.index <= local.columnDataLen; local.index++) {
			arrayAppend(variables.columnArray, {
				name = local.columnData.column_name[local.index],
				type = local.columnData.type_name[local.index]
			});
			variables.columnData[local.columnData.column_name[local.index]] = {
				columnSize = local.columnData.column_size[local.index],
				decimalDigits = local.columnData.decimal_digits[local.index],
				isNullable = local.columnData.is_nullable[local.index],
				ordinalPosition = local.columnData.ordinal_position[local.index],
				type = local.columnData.type_name[local.index]
			};
		}
		
		return this;
	}
	
	public any function getColumnData() {
		return variables.columnData;
	}
	
	public any function getColumnArray() {
		return variables.columnArray;
	}
	
	public any function validateRecord(struct, type) {
		local.message = [];
		local.type = ((arguments.type) ? 'insert' : 'update');
	
		for (local.field in variables.columnData) {
			
			if (local.type == 'insert' && (local.field == variables.model.getMapping().primaryKey)) { continue; }
			if (local.type == 'update' && !structKeyExists(arguments.struct, local.field)) { continue; }
			
			if (structKeyExists(arguments.struct, local.field)) {
				local.error = this.validateField(local.field, arguments.struct[local.field]);	
			}
			else {
				local.error = this.validateField(local.field);	
			}
			
			if (!structIsEmpty(local.error)) {
				arrayAppend(local.message, local.error);
			}	
		}
		
		return local.message;
	}
	
	public any function validateField(fieldName, value) {
		local.valid = true;
		local.field = variables.columnData[arguments.fieldName];

		if ((variables.columnData[arguments.fieldName].isNullable == 'YES') && !structKeyExists(arguments, 'value')) {
			return {};
		}
		
		if ((variables.columnData[arguments.fieldName].isNullable == 'NO') && !structKeyExists(arguments, 'value')) {
			
			local.param = variables.model.formatValue(fieldName, '');
			
			if (structKeyExists(local.param, 'value') && len(trim(local.param.value))) {
				return {};
			}
			
			return {
				'message' = '#arguments.fieldName# is not nullable.',
				'field' = arguments.fieldName
			};
		}

		switch (local.field.type) {
			case 'int' :
				local.valid = isValid('integer', arguments.value);
				break;			
			
			case 'boolean' :
			case 'bit' :
				local.valid = isValid('boolean', arguments.value);
				break;
			
			case 'float' :
			case 'decimal' :
				local.valid = isValid('float', arguments.value);
				break;
			
			case 'timestamp' : 
			case 'datetime' : 
			case 'date' :
				local.valid = isValid('date', arguments.value);
				break;
				
			default : // string
				if (len(arguments.value) <= local.field.columnSize) {
					local.valid = true;
				}
				else {
					local.valid = false;
				}
				break;
		}
		
		if (local.valid) {
			return {};
		}
		else {
			return {
				'message' = 'The value of `#arguments.value#` for column `#arguments.fieldName#` must be of type `#variables.columnData[arguments.fieldName].type#`.',
				'value' = arguments.value,
				'field' = arguments.fieldName
			};
		}
	}
}