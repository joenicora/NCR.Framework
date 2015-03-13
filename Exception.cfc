component accessors = 'true' {
	property type = 'string' name = 'label';
	property type = 'string' name = 'message';
	property type = 'string' name = 'detail';
	property type = 'date' name = 'timestamp';
	
	public com.ncr.Exception function init(config) {
		if (structKeyExists(arguments.config, 'label')) {
			this.setLabel(config.label);
		}
		if (structKeyExists(arguments.config, 'message')) {
			this.setMessage(config.message);
		}
		if (structKeyExists(arguments.config, 'detail')) {
			this.setDetail(config.detail);
		}
		if (structKeyExists(arguments.config, 'data')) {
			this.setData(config.data);
		}
		this.setTimestamp(application.date.getDateTime());
		
		local.logParams = this.getStruct();
		
		if (!structKeyExists(arguments.config, 'level')) {
			local.logParams.level = 'error';	
		}
		
		this['success'] = false;
		
		application.log.write(local.logParams);
		
		return this;
	}
	
	public any function getData() {
		if (structKeyExists(this, 'data')) {
			return this.data;	
		}
		else {
			return javaCast('null', 0);
		}
	}
	
	public any function setData(data) {
		this.data = arguments.data;
	}
	
	public struct function getStruct() {
		local.struct = {
			label = this.getLabel(),
			message = this.getMessage(),
			detail = this.getDetail(),
			data = this.getData(),
			timestamp = this.getTimestamp()
		};
		
		return local.struct;
	}
}