component extends = 'com.ncr.abstract.ExceptionObject' {
	
	public com.ncr.util.Iterator function init(dataObject) {
		
		structClear(variables);
		this.clearExceptions();
		
		if (isStruct(dataObject)) {
			return this;
		}
				
		variables.dataObject = arguments.dataObject;
		variables.seed = 0;
		
		if (isArray(variables.dataObject)) {
			variables.len = arrayLen(variables.dataObject);
		} 
		else {
			if (isQuery(variables.dataObject)) {
				variables.len = variables.dataObject.recordCount;
				variables.fields = getMetaData(variables.dataObject);
				variables.fieldsLen = arrayLen(variables.fields);
				variables.recordPrototype = {};
				
				for (local.index = 1; local.index <= variables.fieldsLen; local.index++) {
					variables.recordPrototype[variables.fields[local.index].name] = true;	
				}	
			}
			else {
				this.addException(variables.dataObject);
			}
		}
		return this; 
	}
	
	public any function next() {
		variables.seed++;
		
		if (isArray(variables.dataObject)) {
			return {
				'index' = variables.seed,
				'len' = variables.len,
				'data' = variables.dataObject[variables.seed]
			};
		}
		else {
			if (isQuery(variables.dataObject)) {
				local.struct = {};
				for (local.field in variables.recordPrototype) {
					local.struct[local.field] = variables.dataObject[local.field][variables.seed];
				}
				return {
					'index' = variables.seed,
					'len' = variables.len,
					'data' = local.struct
				};	
			}
			else {
				return this.getExceptions();
			}
		}
	}
	
	public boolean function hasNext() {
		if (this.hasExceptions()) {
			return false;
		}
		else {
			return (variables.seed < variables.len);	
		}		
	}
	
	public any function get() {
		local.field = arguments[1];

		if (isArray(variables.dataObject)) {
			return variables.dataObject[variables.seed][local.field];
		}
		else {
			local.struct = {};
			for (local.field in variables.recordPrototype) {
				local.struct[local.field] = variables.dataObject[local.field][variables.seed];
			}
			return local.struct[local.field];			
		}
	}
}