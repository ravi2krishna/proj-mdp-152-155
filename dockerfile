# --------- Stage 1: Build WAR using Maven ---------
FROM maven:3.8.7-eclipse-temurin-11 AS builder

WORKDIR /app

# Copy your Maven project files
COPY pom.xml .
COPY src ./src

# Build the project (this will generate a WAR file)
RUN mvn clean package

# --------- Stage 2: Deploy WAR to Tomcat ---------
FROM tomcat:9.0

# Remove default apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the built WAR file from the Maven container
COPY --from=builder /app/target/WebAppCal-1.3.6.war /usr/local/tomcat/webapps/ROOT.war

# Expose the port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]

