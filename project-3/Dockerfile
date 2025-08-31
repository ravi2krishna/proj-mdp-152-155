# Use an official Maven image to build the app
FROM maven:3.8.6-eclipse-temurin AS build

WORKDIR /app

# Copy project files and build
COPY . .
RUN mvn clean package -DskipTests

# Use Tomcat as base image to run the app
FROM tomcat:9.0

# Remove default web apps and deploy our WAR
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
