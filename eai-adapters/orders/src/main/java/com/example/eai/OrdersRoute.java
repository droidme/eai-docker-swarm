package com.example.eai;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class OrdersRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {

        from("timer:processData?period=30000")
                .routeId("sample-data-processing")
                .log("Processing sample data...")
                .setBody(constant("{\"message\":\"Orders data processed\",\"timestamp\":\"${date:now}\"}"))
                .log("Orders processing completed: ${body}");

    }
}
