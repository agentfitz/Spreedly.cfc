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