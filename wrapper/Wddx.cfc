<cfcomponent>
	<cffunction access="public" name="init" returnType="any">
		<cfreturn this />
	</cffunction>

    <cffunction access="public" name="execute" returnType="any">
    	<cfargument name="param" required="yes" type="struct" />
    	
    	<cfset local.args = { output = 'output' } />
    	<cfset local.args.putAll(arguments.param) />
    	
		<cfwddx attributeCollection = "#local.args#" />
    	
		<cfreturn output />
    </cffunction>

</cfcomponent>