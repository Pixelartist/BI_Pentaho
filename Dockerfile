FROM debian:latest
MAINTAINER Manuel Mueller

RUN apt-get update && apt-get upgrade -y

#java
RUN apt-get -y install default-jre default-jdk wget ant git nano procps
#set JAVA_HOME
RUN JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")


#tomcat
RUN wget http://apache.uberglobalmirror.com/tomcat/tomcat-9/v9.0.0.M22/bin/apache-tomcat-9.0.0.M22.tar.gz
RUN mkdir /opt/tomcat
RUN tar -C /opt/tomcat -zxf apache-tomcat-9.0.0.M22.tar.gz --strip-components 1
RUN rm apache-tomcat-9.0.0.M22.tar.gz
RUN rm -rf /opt/tomcat/webapps/examples /opt/tomcat/webapps/docs

COPY scripts/tomcat /etc/init.d/tomcat
COPY conf/tomcat-users.xml /opt/tomcat/conf/
RUN chmod 755 /etc/init.d/tomcat
RUN update-rc.d tomcat defaults

# Expose web port
EXPOSE 8080

# Set environment
ENV CATALINA_HOME /opt/tomcat

# Launch Tomcat on startup
CMD ${CATALINA_HOME}/bin/catalina.sh run
