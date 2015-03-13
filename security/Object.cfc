component {

	variables.permissionArray = [];
	variables.collection = {};

	public com.ncr.security.Object function init(config = {}) {		
		variables.collection.putAll(arguments.config);
		return this;
	}

	public com.ncr.security.Object function can(permission) {
		
		if (!isSimpleValue(arguments.permission) && !isArray(arguments.permission)) {
			return this;
		}
		
		local.permissionArray = ((isArray(arguments.permission)) ? arguments.permission : [arguments.permission]);
		variables.permissionArray = local.permissionArray;
		
		return this;
	}
	
	public boolean function with(feature) {
		
		if(!arrayLen(variables.permissionArray)) { return false; }
		
		local.featureArray = ((isArray(arguments.feature)) ? arguments.feature : [arguments.feature]);
		local.featureArrayLen = arrayLen(local.featureArray);
		local.permissionArray = variables.permissionArray;
		local.permissionArrayLen = arrayLen(local.permissionArray);
		local.can = true;
		
		for (local.index = 1; local.index <= local.featureArrayLen; local.index++) {
			
			if (!structKeyExists(variables.collection, local.featureArray[local.index])) {
				return false;
			}
			
			local.ownerPermissionArray = variables.collection[local.featureArray[local.index]];
			
			local.ownerPermissionArrayLen = arrayLen(local.ownerPermissionArray);
			for (local.iindex = 1; local.iindex <= local.permissionArrayLen; local.iindex++) {
				if (local.ownerPermissionArray.indexOf(local.permissionArray[local.iindex]) == -1) {
					local.can = false;
					break;
				}
			}
		}
		
		return local.can;
	}

}