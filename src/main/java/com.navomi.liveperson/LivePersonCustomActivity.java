package com.navomi.liveperson;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

@Path("/api/execute")
public class LivePersonCustomActivity {

    /**
     * This method is called when a user clicks on the activity in the LivePerson UI.
     *
     * @return
     */
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public String execute() {
            return "{ \"status\": \"success Dan!\" }";
    }

}
