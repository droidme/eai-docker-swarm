FROM openjdk:17-jdk-slim

LABEL maintainer="EAI Team"
LABEL description="EAI Orders Adapter"

WORKDIR /app

RUN groupadd -r eai && useradd -r -g eai eai

COPY target/eai-adapter-orders-*.jar app.jar

RUN chown -R eai:eai /app

USER eai

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENV JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseG1GC"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
