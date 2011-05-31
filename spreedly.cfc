<cfcomponent hint="This is the Spreedly API. Structs in, structs out.">
  
  <cfscript>
    variables.token = "your_spreedly_token";
    variables.site = "your_spreedly_site_name";
    variables.password = "X";
  </cfscript>
  
  <!---
  Convert Structures/Arrays (including embedded) to XML.
  @param input      Data to convert into XML. (Required)
  @param element      Used to name the root element. (Required)
  @return Returns a string. 
  @author Phil Arnold (philip.r.j.arnold@googlemail.com) 
  @version 0, September 9, 2009 
  --->
  <cffunction name="toXML" output="false" returntype="String">
    <cfargument name="input" type="Any" required="true" />
    <cfargument name="element" type="string" required="true" />
    <cfscript>
      var i = 0;
      var s = "";
      var s1 = "";
      s1 = arguments.element;
      if (right(s1, 1) eq "s") {
        s1 = left(s1, len(s1)-1);
      }
      s = s & "<#lcase(arguments.element)#>";
      if (isArray(arguments.input)) {
        for (i = 1; i lte arrayLen(arguments.input); i = i + 1) {
          if (isSimpleValue(arguments.input[i])) {
            s = s & "<#lcase(s1)#>" & arguments.input[i] & "</#lcase(s1)#>";
          } else {
            s = s & toXML(arguments.input[i], s1);
          }
        }
      } else if (isStruct(arguments.input)) {
        for (i in arguments.input) {
          if (isSimpleValue(arguments.input[i])) {
            s = s & "<#lcase(i)#>" & arguments.input[i] & "</#lcase(i)#>";
          } else {
            s = s & toXML(arguments.input[i], i);
          }
        }
      } else {
        s = s & XMLformat(arguments.input);
      }
      s = s & "</#lcase(arguments.element)#>";
    </cfscript>
    <cfreturn s />
  </cffunction>
  
  <cffunction name="toStruct" access="public" returntype="struct" output="false" hint="Parse raw XML response body into ColdFusion structs and arrays and return it.">
    <cfargument name="xmlNode" type="string" required="true" />
    <cfargument name="str" type="struct" required="true" />
    <cfset var i = 0 />
    <cfset var axml = arguments.xmlNode />
    <cfset var astr = arguments.str />
    <cfset var n = "" />
    <cfset var tmpContainer = "" />
    <cfset axml = XmlSearch(XmlParse(arguments.xmlNode),"/node()")>
    <cfset axml = axml[1] />
    <cfloop from="1" to="#arrayLen(axml.XmlChildren)#" index="i">
      <cfset n = replace(axml.XmlChildren[i].XmlName, axml.XmlChildren[i].XmlNsPrefix&":", "") />
      <cfif structKeyExists(astr, n)>
        <cfif not isArray(astr[n])>
          <cfset tmpContainer = astr[n] />
          <cfset astr[n] = arrayNew(1) />
          <cfset astr[n][1] = tmpContainer />
        <cfelse>
        </cfif>
        <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
          <cfset astr[n][arrayLen(astr[n])+1] = toStruct(axml.XmlChildren[i], structNew()) />
        <cfelse>
          <cfset astr[n][arrayLen(astr[n])+1] = axml.XmlChildren[i].XmlText />
        </cfif>
      <cfelse>
        <cfif arrayLen(axml.XmlChildren[i].XmlChildren) gt 0>
          <cfset astr[n] = toStruct(axml.XmlChildren[i], structNew()) />
        <cfelse>
           <cfset astr[n] = axml.XmlChildren[i].XmlText />
        </cfif>
      </cfif>
    </cfloop>
    <cfreturn astr />
  </cffunction>

  <cffunction name="init" access="public" returnType="any" output="no">
    <cfreturn this>
  </cffunction>

  <cffunction name="_request" access="private">
    <cfargument name="path">
    
    <cftry>
        
	    <cfhttp url="https://spreedly.com/api/v4/#variables.site#/#arguments.path#.xml" method="#arguments.method#" username="#variables.token#" password="#variables.password#">
	      <cfhttpparam type="header" name="Content-Type" value="application/xml" />
	      <cfif arguments.method EQ "GET">
	        <!--- Spreedly doesnt use GET variables in their API, so this is not used --->
	        <cfloop collection=#arguments# item="param">
	          <cfhttpparam type="URL" name="#LCase(param)#" value="#StructFind(arguments, param)#">
	        </cfloop>
	      <cfelseif arguments.method NEQ "GET">
	        <!--- any Struct passed in as the "obj" argument will get converted to XML and submitted as the body of the HTTP request --->
	        <!--- an argument named "root" must also be passed in to indicate the root node name for the XML conversion --->
	        <cfset xmlString = toXML(arguments.obj,arguments.root)>
	        <cfhttpparam type="Body" value="#xmlString#">
	      </cfif>
	    </cfhttp>
        
	    <cfswitch expression="#ListFirst(cfhttp.statusCode, " ")#">
	      <cfcase value="500">
	        <!--- 500 INTERNAL SERVER ERROR --->
	        <cfreturn {"error":"500"}>
	      </cfcase>
	      <cfcase value="422">
	        <!--- 422 UNPROCESSABLE ENTITY   Sent in response to a POST (create) or PUT (update) request that is invalid. --->
	        <cfreturn {"error":"422"}>
	      </cfcase>
	      <cfcase value="404">
	        <!--- 404 NOT FOUND  The requested resource was not found. --->
	        <cfreturn {"error":"404"}>
	      </cfcase>
	      <cfcase value="403">
	        <!--- 403 FORBIDDEN  Returned by valid endpoints in our application that have not been enabled for API use. --->
	        <cfreturn {"error":"403"}>
	      </cfcase>
	      <cfcase value="401">
	        <!--- 401 UNAUTHORIZED Returned when API authentication has failed. --->
	        <cfreturn {"error":"401"}>
	      </cfcase>
	      <cfcase value="201">
	        <!--- 201 CREATED The resource was successfully created. Sent in response to a POST (create) request with valid data. --->
	      </cfcase>
	      <cfcase value="200">
	        <!--- 200 OK The request succeeded and a response was sent. Usually in response to a GET (read) request, but also for successful PUT (update) requests.--->
	      </cfcase>
	      <cfdefaultcase>
	        <!--- ???? --->
	      </cfdefaultcase>
	    </cfswitch>
    
	    <cfcatch>
	      <cfreturn {}>
	    </cfcatch>

    </cftry>
  
    <cfreturn toStruct(cfhttp.FileContent,StructNew())>

  </cffunction>
  
  <cfscript>
  
	  // Create a subscribe link URL
	  // https://spreedly.com/meresheep-test/subscribers/44763/d21de2b33ed811c1a040a507988241f550c45aee/subscribe/41
	  // required: plan, id
	  // optional: token
	  function subscribe_url() {
	    var thisUrl = "https://spreedly.com/#variables.site#/subscribers/#arguments.id#/";
	    if (isDefined("arguments.token")) {
	      thisUrl = thisUrl & "#arguments.token#/";
	    }
	    thisUrl = thisUrl & "subscribe/#arguments.plan#";
	    return thisUrl;
	  }
  
	  // Create a subscription detail URL
	  // https://spreedly.com/[short site name]/subscriber_accounts/[spreedly token]
	  // required: token
	  function detail_url() {
	    return "https://spreedly.com/#variables.site#/subscriber_accounts/#arguments.token#";
	  }
  
	  // Get a subscriber’s details
	  // GET /api/v4/[short site name]/subscribers/[customer_id].xml
	  // required: id
	  function detail() {
	    return _request(
	      path="subscribers/#arguments.id#",
	      method="GET"
	    );
	  }
  
	  // Create a subscriber
	  // POST /api/v4/[short site name]/subscribers.xml
	  // required: data
	  function create() {
	    return _request(
	      path="subscribers",
	      method="POST",
	      obj=arguments.data,
	      root="subscriber"
	    );
	  }
  
	  // Update a Subscriber
	  // PUT /api/v4/[short site name]/subscribers/[customer_id].xml
	  // required: id, data
	  function update() {
	    return _request(
	      path="subscribers/#arguments.id#",
	      method="PUT",
	      obj=arguments.data,
	      root="subscriber"
	    );
	  }
  
	  // Give a subscriber a complimentary subscription
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/complimentary_subscriptions.xml

	  // Give a subscriber a complimentary time extension
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/complimentary_time_extensions.xml
	  // <complimentary-time-extension><duration-quantity>2</duration-quantity><duration-units>months</duration-units></complimentary-time-extension>
	  // required: id, data
	  function time_extension() {
	    return _request(
	      path="subscribers/#arguments.id#/complimentary_time_extensions",
	      method="POST",
	      obj=arguments.data,
	      root="complimentary-time-extension"
	    );
	  }

	  // Give a subscriber a lifetime complimentary subscription
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/lifetime_complimentary_subscriptions.xml

	  // Give a subscriber a store credit
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/credits.xml

	  // Adding a fee to a subscriber
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/fees.xml

	  // Programatically Stopping Auto Renew of a Subscriber
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/stop_auto_renew.xml

	  // Programatically Subscribe a Subscriber to a Free Trial Plan
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/subscribe_to_free_trial.xml
	  // ex: <subscription-plan><id>2</id></subscription-plan>
	  // required: id, data
	  function free_trial() {
	    return _request(
	      path="subscribers/#arguments.id#/subscribe_to_free_trial",
	      method="POST",
	      obj=arguments.data,
	      root="subscription-plan"
	    );
	  }

	  // Programatically Allow Another Free Trial
	  // POST /api/v4/[short site name]/subscribers/[customer_id]/allow_free_trial.xml
	  function allow_free_trial() {
	    return _request(
	      path="subscribers/#arguments.id#/allow_free_trial",
	      method="POST"
	    );
	  }

	  // Get a list of all subscribers
	  // GET /api/v4/[short site name]/subscribers.xml
	  function subscribers() {
	    return _request(
	      path="subscribers",
	      method="GET"
	    );
	  }

	  // Subscription Plan API

	  // Get a list of all subscription plans
	  // GET /api/v4/[short site name]/subscription_plans.xml
	  function plans() {
	    return _request(
	      path="subscription_plans",
	      method="GET"
	    );
	  }

	  // Payments API

	  // Create an Invoice
	  // POST /api/v4/[short site name]/invoices.xml

	  // Pay an Invoice
	  // PUT /api/v4/[short site name]/invoices/[invoice token]/pay.xml

	  // Test API

	  // Clear all subscribers from a *test* site
	  // DELETE /api/v4/[short site name]/subscribers.xml

	  // Delete one subscriber from a *test* site
	  // DELETE /api/v4/[short site name]/subscribers/[customer_id].xml
    
  </cfscript>

</cfcomponent>