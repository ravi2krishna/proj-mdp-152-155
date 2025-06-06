FROM maven:3.8.4-openjdk-11 AS build
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

FROM tomcat:9.0-jdk11-openjdk-slim
WORKDIR /usr/local/tomcat/webapps
COPY --from=build /app/target/*.war ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
