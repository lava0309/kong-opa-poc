FROM eclipse-temurin:21.0.2_13-jdk-jammy AS builder
WORKDIR /opt/app
COPY gradle/ gradle
COPY gradlew build.gradle ./
COPY ./src ./src
RUN ./gradlew clean build -x test

FROM eclipse-temurin:21.0.2_13-jre-jammy AS final
WORKDIR /opt/app
EXPOSE 8082
COPY --from=builder /opt/app/build/libs/*.jar /opt/app/*.jar
ENTRYPOINT ["java", "-jar", "/opt/app/*.jar"]