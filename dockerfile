FROM maven:3.8.5-openjdk-17 as stage-1

WORKDIR /app

COPY ./pom.xml .
RUN mvn dependency:go-offline
COPY ./src ./src 

RUN mvn clean verify sonar:sonar \ 
    -Dsonar.projectKey=calculator-inspector \
    -Dsonar.projectName="calculator inspector" \ 
    -Dsonar.host.url=http://172.31.28.183:9000 \
    -Dsonar.token=${SONAR_KEY}

FROM alpine:3.14 as uploader

RUN apt update && apt install -y curl \
    && curl -fL https://getcli.jfrog.io | sh \
    && mv jfrog /usr/local/bin/jfrog

WORKDIR /app

ENV ARTIFACTORY_TARGET_PATH=calculator-java/
ENV ARTIFACTORY_CREDENTIALS=${JFROG_KEY}

COPY --from=stage-1 /app/target/Calculator-1.0-SNAPSHOT.jar /app/Calculator-1.0-SNAPSHOT.jar


RUN jfrog rt u /app/Calculator-1.0-SNAPSHOT.jar ${ARTIFACTORY_TARGET_PATH} \
    --url http://172.31.24.217:8082/artifactory/ --access-token ${ARTIFACTORY_CREDENTIALS}

FROM openjdk:17-slim as stage-2
WORKDIR /app

COPY --from=stage-1 /app/target/Calculator-1.0-SNAPSHOT.jar /app/Calculator-1.0-SNAPSHOT.jar


CMD ["java", "-jar", "/app/Calculator-1.0-SNAPSHOT.jar"]
