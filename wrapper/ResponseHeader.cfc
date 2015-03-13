<cfcomponent>
	<cffunction access="public" name="init" returnType="any">
		<cfreturn this />
	</cffunction>

    <cffunction access="public" name="setHeader" returnType="void">
    	<cfargument name="param" required="yes" type="struct" />
    	
    	<cfset local.args = { output = 'output' } />
    	<cfset local.args.putAll(arguments.param) />
    	
		<cfheader attributeCollection = "#local.args#" />
    </cffunction>

</cfcomponent>