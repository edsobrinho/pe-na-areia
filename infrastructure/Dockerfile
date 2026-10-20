FROM gradle:8.10.2-jdk21 AS build

WORKDIR /workspace/backend
COPY backend/build.gradle backend/settings.gradle backend/
COPY backend/gradle backend/gradle
COPY backend/gradlew backend/
COPY backend/src backend/src
RUN chmod +x gradlew && ./gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre

WORKDIR /app
COPY --from=build /workspace/backend/build/libs/pe-na-areia-backend-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
