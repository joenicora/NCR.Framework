<cfcomponent>
	<cffunction access="public" name="init" returnType="any">
		<cfreturn this />
	</cffunction>

    <cffunction access="public" name="login" returnType="void">
    	<cfargument name="param" required="yes" type="struct" />
    	
    	<cfset local.param = arguments.param />

    	<cflogin idletimeout="3600">
			<cfloginuser name="#local.param.name#" password="#local.param.password#" roles="#local.param.roles#" />
    	</cflogin>
    </cffunction>
    
    <cffunction access="public" name="logout" returnType="void">
		<cflogout />
    </cffunction>

</cfcomponent>