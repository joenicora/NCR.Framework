component {
	
	public com.ncr.util.ToolBox function init() {
		return this; 
	}
	
	public void function sleep(required numeric milliseconds) {
		createObject("java", "java.lang.Thread").sleep(arguments.milliseconds);
	}
	
	public string function applyTemplate(required string template, required struct applied, required string parent = '') {
		local.tpl = arguments.template;
		local.data = arguments.applied;
		local.parent = ((len(arguments.parent)) ? (arguments.parent & '.') : '');
			
		if (isArray(data)) {
			
			local.dataLen = arrayLen(local.data);
			
			for (local.index = 1; local.index <= local.dataLen; local.index++) {
			
				if (isArray(local.data[local.index]) || isStruct(local.data[local.index])) {
					local.tpl = this.applyTemplate(local.tpl, local.data[local.index], local.parent & local.key);
				}
				else {
					local.token = arrayToList(['{',local.parent,local.index,'}'], '');
					local.tpl = replaceNoCase(local.tpl, local.token, local.data[local.index], 'all');
				}
				
			}
		}
		
		if (isStruct(data)) { 
					
			for (local.key in local.data) {
				
				if (isArray(local.data[local.key]) || isStruct(local.data[local.key])) {
					local.tpl = this.applyTemplate(local.tpl, local.data[local.key], local.parent & local.key);
				}
				else {
					local.token = arrayToList(['{',local.parent,local.key,'}'], '');
					local.tpl = replaceNoCase(local.tpl, local.token, local.data[local.key], 'all');
				}
			}
		}
		
		return local.tpl;	
	}
	
	public void function directoryExistsCreate(required string filePath) {
		local.filePathArray = listToArray(arguments.filePath, '/');
		local.directoryPathArray = duplicate(local.filePathArray);
		
		arrayDeleteAt(local.directoryPathArray, arrayLen(local.directoryPathArray));
		
		local.directoryPathArrayLen = arrayLen(local.directoryPathArray);
		local.incrementDirectory = [];
		
		if (!directoryExists(arrayToList(local.directoryPathArray, '/'))) {
			for(local.ix = 1; local.ix <= local.directoryPathArrayLen; local.ix++) {
				arrayAppend(local.incrementDirectory, local.directoryPathArray[local.ix]);
				local.currentDirectory = '/' & arrayToList(local.incrementDirectory, '/');
				if (!directoryExists(local.currentDirectory)) {
					directoryCreate(local.currentDirectory);
				}
			}
		}
	}
	
	public string function getBaseUrl() {
		local.href = 'http://' & this.getHostAddress() & application.environment.port & '/';
		
		return local.href;
	}
	
	public string function getHostAddress() {
		return server_name;
	}
	
}