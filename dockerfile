#Dockerfile
#

#BASE IMAGE
FROM maven:3.5.4-jdk-8-alpine AS build

#SET UP PROJECT CONTEXT
RUN mkdir /calculator
WORKDIR /calculator

#App Code
COPY . /calculator

#Build APP
RUN mvn dependency:go-offline -B
RUN mvn package

#Deploy APP
FROM tomcat

#Copy Build Artifacts
COPY --from=build /calculator/target/WebAppCal-1.3.5.war /usr/local/tomcat/webapps/

