FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace/backend
COPY backend/ ./
RUN chmod +x gradlew && ./gradlew --no-daemon bootJar -x test

FROM eclipse-temurin:21-jre

WORKDIR /app
COPY --from=build /workspace/backend/build/libs/pe-na-areia-backend-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
