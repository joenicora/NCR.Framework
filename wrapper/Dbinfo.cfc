<cfcomponent>
	<cffunction access="public" name="init" returnType="any">
		<cfreturn this />
	</cffunction>

    <cffunction access="public" name="getContext" returnType="any">
    	<cfargument name="param" required="yes" type="struct" />
    	
    	<cfset local.args = { name = 'info' } />
    	<cfset local.args.putAll(arguments.param) />
    	
		<cfdbinfo attributeCollection = "#local.args#" />
    	
		<cfreturn info />
    </cffunction>

</cfcomponent>