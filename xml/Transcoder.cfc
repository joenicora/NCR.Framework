component {
	
	/*
		Not currently accepting XML to CF conversions for data types of Query or Component
		Table data can be encoded to CF with an array of structs
	*/	

	public com.ncr.xml.Transcoder function init() {
		return this;
	}
	
	public string function toXml(required any coldfusion, string nodeName = 'root') {
		local.current = '';
		local.type = this.getTypeOf(arguments.coldfusion);
		local.parsers = {
			'struct' = this.structToXml,
			'array' = this.arrayToXml,
			'query' = this.queryToXml,
			'component' = this.componentToXml,
			'unknown' = this.unknownToXml
		};
		
		arguments.nodeName = replace(arguments.nodeName, ':', '..');
		
		local.nodeArray = ['<#arguments.nodeName#'];
		
		if (local.type == 'simple') {
			arrayAppend(local.nodeArray, ' cf_type="#this.getSimpleTypeOf(arguments.coldfusion)#">');
			arrayAppend(local.nodeArray, '<![CDATA[#xmlFormat(arguments.coldfusion)#]]>');
		}
		else {
			arrayAppend(local.nodeArray, ' ');
			arrayAppend(local.nodeArray, 'cf_type="#local.type#">');
			local.parser = local.parsers[local.type];
			arrayAppend(local.nodeArray, local.parser(arguments.coldfusion, arguments.nodeName));
		}
		
		arrayAppend(local.nodeArray, '</#arguments.nodeName#>');

		return arrayToList(local.nodeArray, '');
	}
	
	public boolean function _isSimpleValue(value) { return isSimpleValue(arguments.value); };
	
	public boolean function _isStruct(value) { return (isStruct(arguments.value) && !this.isComponent(arguments.value)); };
	
	public boolean function _isArray(value) { return isArray(arguments.value); };
	
	public boolean function _isQuery(value) { return isQuery(arguments.value); };
	
	public boolean function isComponent(required any component) {
		return ((structKeyExists(getMetaData(arguments.component), 'type') && getMetaData(arguments.component).type == 'component') ? true : false);
	}
	
	public string function getTypeOf(required any variable) {
		local.types = {
			'simple' = this._isSimpleValue,
			'struct' = this._isStruct,
			'array' = this._isArray,
			'query' = this._isQuery,
			'component' = this.isComponent
		};
		
		return this.typeOf(arguments.variable, local.types);
	}
	
	public string function getSimpleTypeOf(required any variable) {
		if (isNumeric(arguments.variable)) {
			local.type = 'numeric';
		}
		else if (isBoolean(arguments.variable)) {
			local.type = 'boolean';
		}
		else if (isDate(arguments.variable)) {
			local.type = 'date';
		}
		else {
			local.type = 'string';
		}
		
		return local.type;
	}
	
	public string function typeOf(required any variable, required struct types) {
		local.types = arguments.types;
	
		for (local.type in local.types) {
			local.test = local.types[local.type];
			if (local.test(arguments.variable) == true) {
				return local.type;
			}
		}
		
		return 'unknown';
	}
	
	public string function structToXml(required struct struct) {
		local.nodeArray = [];
		
		for (local.key in arguments.struct) {
			arrayAppend(local.nodeArray, this.toXml(arguments.struct[local.key], local.key));
		}
		
		return arrayToList(local.nodeArray, '');
	}
	
	public string function arrayToXml(required array array, required string nodeName) {
		local.nodeArray = [];
		local.arrayLen = arrayLen(arguments.array);
		
		for (local.index = 1; local.index <= local.arrayLen; local.index++) {
			arrayAppend(local.nodeArray, this.toXml(arguments.array[local.index], arguments.nodeName & '-item'));
		}
		
		return arrayToList(local.nodeArray, '');
	}
	
	public string function queryToXml(required query query) {
		local.query = arguments.query;
		local.struct = { 'data' = [] };
		local.columns = local.query.getColumnNames();
		local.columnsLen = arrayLen(local.columns);
		
		for (local.index = 1; local.index <= local.query.recordCount; local.index++) {
			local.record = {};
			for (local.iindex = 1; local.iindex <= local.columnsLen; local.iindex++) {
				local.record[local.columns[local.iindex]] = local.query[local.columns[local.iindex]][local.index];
			}
			arrayAppend(local.struct.data, local.record);
		}

		return this.toXml(local.struct.data, 'data');
	}
	
	public string function componentToXml(required any component) {
		return this.toXml(getMetaData(arguments.component), 'component');
	}
	
	public string function unknownToXml(required any unknown, required string nodeName) {
		return '<#arguments.nodeName#>unknown</#arguments.nodeName#>';
	}
	
	public any function toCf(required xml xml) {
		local.xml = ((!isSimpleValue(arguments.xml)) ? arguments.xml : xmlParse(arguments.xml));
		local.xml.xmlName = replace(local.xml.xmlName, '..', ':');
		local.cf = {};

		if (structKeyExists(local.xml, 'xmlRoot')) {
			local.xml = local.xml.xmlRoot;
		}

		local.type = this.xmlTypeOf(local.xml);
		
		switch (local.type) {
			case 'struct' :
				local.children = local.xml.xmlChildren;
				local.childrenLen = arrayLen(local.children);
				local.cf[local.xml.xmlName] = {};
				
				for (local.index = 1; local.index <= local.childrenLen; local.index++) { 
					local.cf_val = this.toCf(local.children[local.index]);
					local.cf[local.xml.xmlName][local.children[local.index].xmlName] = local.cf_val[local.children[local.index].xmlName];
				}
				break;
			
			case 'array' :
				local.children = local.xml.xmlChildren;
				local.childrenLen = arrayLen(local.children);
				local.cf[local.xml.xmlName] = [];

				for (local.index = 1; local.index <= local.childrenLen; local.index++) {
					local.cf_val = this.toCf(local.children[local.index]);
					arrayAppend(local.cf[local.xml.xmlName], local.cf_val[local.xml.xmlName & '-item']);
				}
				break;
				
			default : // simple values
				local.cf[local.xml.xmlName] = local.xml.xmlText;
				break;
		}

		return local.cf;
	}
		
	public any function xmlTypeOf(required xml xml) {
		local.xml = arguments.xml;
		local.attributes = ((structKeyExists(local.xml, 'xmlAttributes')) ? local.xml.xmlAttributes : {});
		
		if (structKeyExists(local.attributes, 'cf_type')) {
			return local.attributes['cf_type'];
		}
		else {
			return 'array';
		}
	}
	
	public string function indent(required string xml) {
		local.xml = arguments.xml;
		local.indent = '  ';
		local.lines = '';
		local.line = '';
		local.isCDATAStart = '';
		local.isCDATAEnd = '';
		local.isEndTag = '';
		local.isSelfClose = '';
		local.xml = trim(REReplace(local.xml, "(^|>)\s*(<|$)", "\1#chr(10)#\2", "all"));
		local.lines = listToArray(local.xml, chr(10));
		local.linesLen = arrayLen(local.lines);
		local.depth = 0;
		
		for (local.index = 1; local.index <= local.linesLen; local.index++) {
			local.line = trim(local.lines[local.index]);
			local.isCDATAStart = left(local.line, 9) == "<![CDATA[";
			local.isCDATAEnd = right(local.line, 3) == "]]>";
		
			if (!local.isCDATAStart && !local.isCDATAEnd && left(local.line, 1) == "<" && right(local.line, 1) == ">") {
				local.isEndTag = left(local.line, 2) == "</";
				local.isSelfClose = right(local.line, 2) == "/>" || REFindNoCase("<([a-z0-9_-]*).*</\1>", local.line);
				if (local.isEndTag) {
					local.depth = max(0, local.depth - 1);
				}
				local.lines[local.index] = repeatString(local.indent, local.depth) & local.line;
				if (!local.isEndTag && !local.isSelfClose) {
					local.depth = local.depth + 1;
				}
			}
			else if (local.isCDATAStart) {
				local.lines[local.index] = repeatString(local.indent, local.depth) & local.line;
			}
		}
		
		return arrayToList(local.lines, chr(10));
	}
}