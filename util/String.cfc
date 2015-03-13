component {
	
	public com.ncr.util.String function init() {
		return this;
	}
	
	public string function stripHtml(required string str) {
		local.str = reReplaceNoCase(arguments.str, "<*style.*?>(.*?)</style>","","all");
	    local.str = reReplaceNoCase(local.str, "<*script.*?>(.*?)</script>","","all");
	
	    local.str = reReplaceNoCase(local.str, "<.*?>","","all");
	    local.str = reReplaceNoCase(local.str, "^.*?>","");
	    local.str = reReplaceNoCase(local.str, "<.*$","");
	    
	    return trim(local.str);
	}
	
}