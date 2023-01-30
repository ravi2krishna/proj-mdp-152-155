# Base Image
FROM maven:3.8.7-eclipse-temurin-11 AS builder

# Setup Project Dir
RUN mkdir /webcal

# Set Context
WORKDIR /webcal

# Copy App Code
COPY . /webcal

# Perform Build
RUN mvn package

# For Deployment

# Base Image tomcat
FROM tomcat:8.0

# Deploy Built code from 1st step
COPY --from=builder /webcal/target/WebAppCal-1.3.5.war /usr/local/tomcat/webapps
