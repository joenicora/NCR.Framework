component {
	this['exceptionStack'] = [];
	
	public com.ncr.abstract.ExceptionObject function init() {
		return this;
	}
	
	public void function addException(param) {
		if (getMetaData(arguments.param).name == 'com.ncr.Exception') {
			arrayAppend(this.exceptionStack, arguments.param);	
		}
		else {
			local.exceptionParam = {
				level = ((structKeyExists(arguments.param, 'level')) ? arguments.param.level : 'error'),
				label = arguments.param.label,
				message = arguments.param.message,
				detail = ((structKeyExists(arguments.param, 'detail')) ? arguments.param.detail : '')
			};
			
			if (structKeyExists(arguments.param, 'data')) {
				local.exceptionParam.data = arguments.param.data;
			}
			
			arrayAppend(this.exceptionStack, application.new('com.ncr.Exception', local.exceptionParam));	
		}		
	}
	
	public array function getExceptions() {
		return this.exceptionStack;
	}
	
	public boolean function hasExceptions() {
		if (arrayLen(this.exceptionStack) == 0) {
			return false;
		}
		else {
			return true;
		}
	}
	
	public void function clearExceptions() {
		this.exceptionStack = [];
	}
	
	public array function toMessageArray() {
		local.exceptions = this['exceptionStack'];
		local.exceptionsLen = arrayLen(local.exceptions);
		local.messages = [];
		
		for (local.index = 1; local.index <= local.exceptionsLen; local.index++) {
			local.exceptionStruct = local.exceptions[local.index].getStruct();
			if (structKeyExists(local.exceptionStruct, 'data') && structKeyExists(local.exceptionStruct.data, 'field')) {
				arrayAppend(local.messages, {
					'name' = local.exceptionStruct.data.field,
					'message' = local.exceptionStruct.message
				});	
			}
		}
		
		return local.messages;
	}
}