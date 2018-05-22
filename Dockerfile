#FROM ubuntu:16.04
FROM ubuntu:xenial

MAINTAINER Nikhil Rasane

ENV TOMCAT_VERSION 8.5.31
ENV GRADLE_VERSION 4.7

RUN apt-get update && apt-get install -y software-properties-common && apt-get install -y curl && apt-get install -y unzip && apt-get install -y perl

RUN apt-get install dialog apt-utils -y

## add webupd8 repository
RUN \
    echo "===> add webupd8 repository..."  && \
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee /etc/apt/sources.list.d/webupd8team-java.list  && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list  && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886  && \
    apt-get update  && \
    \
    \
    echo "===> install Java"  && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections  && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections  && \
    apt-get install -y oracle-java8-installer oracle-java8-set-default  && \
    \
    \
    echo "===> clean up..."  && \
    rm -rf /var/cache/oracle-jdk8-installer  && \
    apt-get clean  && \
    rm -rf /var/lib/apt/lists/*



## Define JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle


#### Install gradle

RUN cd /usr/lib \
 && curl -fl https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle-bin.zip \
 && unzip "gradle-bin.zip" \
 && ln -s "/usr/lib/gradle-${GRADLE_VERSION}/bin/gradle" /usr/bin/gradle \
 && rm "gradle-bin.zip"

## Set Appropriate Environmental Variables
ENV GRADLE_HOME /usr/lib/gradle
ENV PATH $PATH:$GRADLE_HOME/bin




##### Install tomcat8
RUN mkdir /usr/local/tomcat
RUN wget http://www-us.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz -O /tmp/tomcat.tar.gz
RUN cd /tmp && tar xvfz tomcat.tar.gz
RUN cp -Rv /tmp/apache-tomcat-${TOMCAT_VERSION}/* /usr/local/tomcat/
EXPOSE 8080
CMD /usr/local/tomcat/bin/catalina.sh run







##### Install Postgresql 10
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
#RUN echo "deb http://apt.postgresql.org/pub/repos/apt/dists/xenial-pgdg/main" > /etc/apt/sources.list.d/pgdg.list
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get -y -q install python-software-properties software-properties-common \
    && apt-get install -y -q postgresql-10 postgresql-client-10 postgresql-contrib-10

USER postgres

RUN /etc/init.d/postgresql start \
    && psql --command "CREATE USER pguser WITH SUPERUSER PASSWORD 'pguser';" \
    && createdb -O pguser pgdb

USER root

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/10/main/pg_hba.conf
RUN echo "listen_addresses='*'" >> /etc/postgresql/10/main/postgresql.conf



# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
#RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/10/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
#RUN echo "listen_addresses='*'" >> /etc/postgresql/10/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432


RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql
# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

#WORKDIR /home
#ENTRYPOINT ["/etc/init.d/postgresql", "start"]


USER postgres
CMD ["/usr/lib/postgresql/10/bin/postgres", "-D", "/var/lib/postgresql/10/main", "-c", "config_file=/etc/postgresql/10/main/postgresql.conf"]



####****************################
####Install postgresql 10

#RUN apt-get install dialog apt-utils -y

#RUN apt-get -y install wget sudo
#RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
#RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' >> /etc/apt/sources.list.d/pgdg.list
#RUN apt-get update
#RUN apt-get install postgresql-10 -y
    


####Install postgresql 10

#ENV OS_LOCALE="en_US.UTF-8 en_US hu_HU hu_HU.UTF-8"
#ENV OS_LOCALE="en_US.UTF-8"
#RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}  
#ENV LANG=${OS_LOCALE} \
#    LANGUAGE=${OS_LOCALE} \
#    LC_ALL=${OS_LOCALE} \
#    PG_VERSION=10 \
#    PG_USER=postgres \
#    PG_HOME=/var/lib/postgresql \
#    PG_RUN_DIR=/run/postgresql \
#    PG_LOG_DIR=/var/log/postgresql
    
#ENV PG_CONF_DIR="/etc/postgresql/${PG_VERSION}/main" \
#    PG_BIN_DIR="/usr/lib/postgresql/${PG_VERSION}/bin" \
#    PG_DATA_DIR="${PG_HOME}/${PG_VERSION}/main"

#RUN apt-get install dialog apt-utils -y

#RUN dpkg-reconfigure locales && apt-get install -y wget sudo \
# && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
# && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
# && apt-get update && apt-get install -y postgresql-${PG_VERSION} postgresql-client-${PG_VERSION} postgresql-contrib-${PG_VERSION} lbzip2 \
## Cleaning
# && apt-get purge -y --auto-remove wget \
# && rm -rf ${PG_HOME} \
# && rm -rf /var/lib/apt/lists/* \
# && touch /tmp/.EMPTY_DB


#COPY entrypoint.sh /sbin/entrypoint.sh
#RUN chmod 755 /sbin/entrypoint.sh

#EXPOSE 5432/tcp
#VOLUME ["${PG_HOME}", "${PG_RUN_DIR}"]
#CMD ["/sbin/entrypoint.sh"]

#WORKDIR /home
#ENTRYPOINT ["/etc/init.d/postgresql", "start"]



#RUN apt-get update
#RUN apt-get -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common
#RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
#RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#RUN apt-get update
#RUN apt-get -y install docker-ce=17.03.0~ce-0~ubuntu-xenial
##RUN systemctl daemon-reload
#CMD service docker restart
#CMD service docker status


#CMD docker run --name postgresql -d -p 5432:5432 postg10
#CMD docker exec -it postgresql


