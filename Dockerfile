# ---------- Stage 1: Build the WAR using Maven ----------
FROM maven:3.8.5-openjdk-8 AS builder

WORKDIR /app

# Copy the source code
COPY . .

# Build the WAR file
RUN mvn clean package

# ---------- Stage 2: Deploy WAR to Tomcat ----------
FROM tomcat:8.5

# Clean default webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR file from the build stage and deploy it as ROOT
COPY --from=builder /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]

