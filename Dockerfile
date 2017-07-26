FROM debian:latest
MAINTAINER Manuel Mueller

RUN apt-get update && apt-get upgrade -y

#java
RUN apt-get -y install default-jre default-jdk wget ant git nano procps
#set JAVA_HOME
RUN JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

#########################################
## tomcat 9
#########################################
RUN wget http://apache.uberglobalmirror.com/tomcat/tomcat-9/v9.0.0.M22/bin/apache-tomcat-9.0.0.M22.tar.gz
RUN mkdir /opt/tomcat
RUN tar -C /opt/tomcat -zxf apache-tomcat-9.0.0.M22.tar.gz --strip-components 1
RUN rm apache-tomcat-9.0.0.M22.tar.gz
RUN rm -rf /opt/tomcat/webapps/examples /opt/tomcat/webapps/docs

COPY scripts/tomcat /etc/init.d/tomcat
COPY conf/tomcat-users.xml /opt/tomcat/conf/
RUN chmod 755 /etc/init.d/tomcat
RUN update-rc.d tomcat defaults

#########################################
## pentaho
#########################################
ENV PENTAHO_HOME /opt/pentaho
ENV PENTAHO_JAVA_HOME $JAVA_HOME
ENV PENTAHO_SERVER ${PENTAHO_HOME}/server/pentaho-server

RUN apt-get install -y wget unzip bash postgresql-client ttf-dejavu
RUN mkdir -p ${PENTAHO_HOME}/server
RUN mkdir ${PENTAHO_HOME}/.pentaho
RUN adduser --disabled-password --gecos '' pentaho
RUN chown -R pentaho:pentaho ${PENTAHO_HOME}
USER pentaho
WORKDIR ${PENTAHO_HOME}/server


# Get Pentaho Server
RUN echo http://downloads.sourceforge.net/project/pentaho/Business%20Intelligence%20Server/7.1/pentaho-server-ce-7.1.0.0-12.zip | xargs wget -O- -O tmp.zip && \
    unzip -q tmp.zip -d ${PENTAHO_HOME}/server && \
    rm -f tmp.zip

# Get MS SQL JDBC driver
RUN echo https://download.microsoft.com/download/0/2/A/02AAE597-3865-456C-AE7F-613F99F850A8/enu/sqljdbc_6.0.8112.100_enu.tar.gz | xargs wget -O- -O tmp.tar.gz && \
        tar -zxf tmp.tar.gz && \
    	rm -f tmp.tar.gz && \
    	cp sqljdbc_6.0/enu/jre8/sqljdbc42.jar ${PENTAHO_SERVER}/tomcat/lib/ && \
    	rm -fr sqljdbc_6.0

# Replace outdated Postgresql JDBC driver
RUN rm ${PENTAHO_SERVER}/tomcat/lib/postgresql-9.3-1102-jdbc4.jar && \
          echo https://jdbc.postgresql.org/download/postgresql-9.4.1212.jar | xargs wget -O- -O ${PENTAHO_SERVER}/tomcat/lib/postgresql-9.4.1212.jar

# Disable first-time startup prompt
RUN rm ${PENTAHO_SERVER}/promptuser.sh

# Disable daemon mode for Tomcat
RUN sed -i -e 's/\(exec ".*"\) start/\1 run/' ${PENTAHO_SERVER}/tomcat/bin/startup.sh

# Copy scripts and fix permissions
USER root
COPY scripts ${PENTAHO_HOME}/scripts
COPY config ${PENTAHO_HOME}/config
RUN chown -R pentaho:pentaho ${PENTAHO_HOME}/scripts && chmod -R +x ${PENTAHO_HOME}/scripts
USER pentaho

# Expose web port
EXPOSE 8080

# Set environment /disable for pentaho
#ENV CATALINA_HOME /opt/tomcat

# Launch Tomcat on startup
#CMD ${CATALINA_HOME}/bin/catalina.sh run
ENTRYPOINT ["sh", "-c", "$PENTAHO_HOME/scripts/run.sh"]
