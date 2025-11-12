package io.droidme.eai;

import org.apache.camel.builder.RouteBuilder;
import org.springframework.stereotype.Component;

@Component
public class SampleAdapterRoute extends RouteBuilder {

    @Override
    public void configure() throws Exception {

        from("timer:processData?period=30000")
                .routeId("sample-data-processing")
                .log("Processing sample data...")
                .setBody(constant("{\"message\":\"Sample data processed\",\"timestamp\":\"${date:now}\"}"))
                .log("Sample processing completed: ${body}");


    }
}
