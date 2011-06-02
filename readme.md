Spreedly + ColdFusion
====

This is a partial implementation of the Spreedly API for ColdFusion. Using this component is rather simple. For example:

    <cfscript>
      // create a new spreedly user
      var SP = CreateObject("component", "Spreedly").init();
      var newbie = {
        "customer-id":person.id,
        "screen-name":person.name
      };
      SP.create(data=newbie);
      // assign them a free trial plan
      SP.free_trial(id=person.id,data={"id":"7533"});
    </cfscript>
    
If you are using a CFML engine that doesn't support shorthand JSON-style object creation syntax, try this example instead:

    <cfscript>
      // create a new spreedly user
      SP = CreateObject("component", "Spreedly").init();
      newbie = StructNew();
      newbie["customer-id"] = person.id;
      newbie["screen-name"] = person.name;
      SP.create(data=newbie);
      // assign them a free trial plan
      free_trial_data = StructNew();
      free_trial_data["id"] = "7533";
      SP.free_trial(id=person.id,data=free_trial_data);
    </cfscript>
    
Notes
---

Has only been tested with Railo 3. Will probably work with CF8+ as well.