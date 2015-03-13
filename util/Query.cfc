component {
	public com.ncr.util.Query function init() {
		return this;
	}
	
	public any function run(param) {
		local.query = new com.adobe.coldfusion.Query(argumentCollection = arguments.param);
		
		if (structKeyExists(arguments.param, 'params')) {
			for (local.field in arguments.param.params) {
				local.cftype = ((structKeyExists(arguments.param.params[local.field], 'cftype')) ? arguments.param.params[local.field].cftype : 'string');
				if (local.cftype == 'NULL') {
					local.query.addParam( name = local.field, null = true );
				}
				else {
					local.query.addParam( 
						name = local.field, 
						value = arguments.param.params[local.field].value, 
						cfsqltype = local.cftype 
					);
				}
			}
		}
		
		local.query = local.query.execute();

		return local.query;
	}
	
	public array function getValueList(query, column) {
		local.query = arguments.query;
		local.queryLen = local.query.recordCount;
		local.column = arguments.column;
		local.values = [];
		
		for (local.index = 1; local.index <= local.queryLen; local.index++) {
			arrayAppend(local.values, local.query[local.column][local.index]);
		}
		
		return local.values;
	}
	
	public array function toArray(result) {
		local.result = arguments.result;
		local.resultLen = local.result.recordCount;
		local.columns = getMetaData(local.result);
		local.columnsLen = arrayLen(local.columns);
		local.array = [];

		for (local.index = 1; local.index <= local.resultLen; local.index++) {
			local.record = {};
			for (local.iindex = 1; local.iindex <= local.columnsLen; local.iindex++) {
				local.record[local.columns[local.iindex].name] = local.result[local.columns[local.iindex].name][local.index];
			}
			arrayAppend(local.array, local.record);
		}
		
		return local.array;
	}
}