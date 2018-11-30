FROM openkbs/jdk-mvn-py3

MAINTAINER DrSnowbird "DrSnowbird@openkbs.org"

## -------------------------------------------------------------------------------
## ---- USER_NAME is defined in parent image: openkbs/jdk-mvn-py3-x11 already ----
## -------------------------------------------------------------------------------
ENV USER_NAME=${USER_NAME:-blgz}
ENV HOME=/home/${USER_NAME}

## ----------------------------------------------------------------------------
## ---- To change to different Product version:! ----
## ----------------------------------------------------------------------------

## -- 0.) Product Provider and Name: -- ##
ARG PRODUCT_INSTALL_ROOT_DIR=${PRODUCT_INSTALL_ROOT_DIR:-/var/lib}
ENV PRODUCT_INSTALL_ROOT_DIR=${PRODUCT_INSTALL_ROOT_DIR:-/var/lib}

## -- 1.) Provider, Product Type, Product Name, Product Version: -- ##
ARG PRODUCT_PROVIDER=${PRODUCT_PROVIDER:-bigdata}
ENV PRODUCT_PROVIDER=${PRODUCT_PROVIDER:-bigdata}

ARG PRODUCT_TYPE=${PRODUCT_TYPE:-bigdata}
ENV PRODUCT_TYPE=${PRODUCT_TYPE:-bigdata}

ARG PRODUCT_NAME=${PRODUCT_NAME:-blazegraph}
ENV PRODUCT_NAME=${PRODUCT_NAME:-blazegraph}

ARG PRODUCT_HOME=${PRODUCT_HOME:-${PRODUCT_INSTALL_ROOT_DIR}/${PRODUCT_NAME}}
ENV PRODUCT_HOME=${PRODUCT_HOME:-${PRODUCT_INSTALL_ROOT_DIR}/${PRODUCT_NAME}}

ARG PRODUCT_EXE=${PRODUCT_EXE:-${PRODUCT_NAME}.sh}
ENV PRODUCT_EXE=${PRODUCT_EXE:-${PRODUCT_NAME}.sh}

ENV PRODUCT_FULL_PATH_EXE=${PRODUCT_FULL_PATH_EXE:-${PRODUCT_HOME}/bin/${PRODUCT_EXE}}

## -- 2.) Product Release: -- ##
#ARG PRODUCT_RELEASE=${PRODUCT_RELEASE:-}

## -- 3.) Product Version: -- ##
ARG PRODUCT_VERSION=${PRODUCT_VERSION:-2.1.4}
ENV PRODUCT_VERSION=${PRODUCT_VERSION}

## -- 4.) Product Download Mirror site: -- ##
ARG PRODUCT_OS_BUILD=${PRODUCT_OS_BUILD:-}

## -- 5.) Product Download Mirror site: -- ##
# https://downloads.sourceforge.net/project/bigdata/bigdata/2.1.4/blazegraph.tar.gz
# https://downloads.sourceforge.net/project/blazegraph/blazegraph/2.1.4/blazegraph.tar.gz
ARG PRODUCT_MIRROR_SITE_URL=${PRODUCT_MIRROR_SITE_URL:-https://downloads.sourceforge.net/project}

## -- 6.) Product ports: -- ##
ARG PRODUCT_PORTS=${PRODUCT_PORTS:-9999}
ENV PRODUCT_PORTS=${PRODUCT_PORTS}

## -- 6.) Product Data and Workspace: -- ##
ARG PRODUCT_DATA=${PRODUCT_DATA:-${HOME}/data}
ENV PRODUCT_DATA=${PRODUCT_DATA}
ARG PRODUCT_WORKSPACE=${PRODUCT_WORKSPACE:-${HOME}/workspace}
ENV PRODUCT_WORKSPACE=${PRODUCT_WORKSPACE:-${HOME}/workspace}

#### ------------------------ ####
#### ---- BlazeGraph Server   ####
#### ------------------------ ####
#### (Mapping from PRODUCCT_HOME to product-specific HOME)
ARG BLZG_HOME=${PRODUCT_HOME}
ENV BLZG_HOME=${PRODUCT_HOME}

#### (Log directory option - log Directory) 
ARG BLZG_LOG=${BLZG_LOG:-${PRODUCT_HOME}/log}
ENV BLZG_LOG=${BLZG_LOG:-${PRODUCT_HOME}/log}

#### (blazegraph option - RWStore.properties): 
## -Dbigdata.propertyFile=/opt/blazegraph/conf/RWStore.properties 
ARG BIGDATA_PROPERTY=${BIGDATA_PROPERTY:-${BLZG_HOME}/conf/RWStore.properties}
ENV BIGDATA_PROPERTY=${BIGDATA_PROPERTY:-${BLZG_HOME}/conf/RWStore.properties}

#### (blazegraph option - Jetty Web Overwride Web.xml): 
## -Djetty.overrideWebXml=/opt/blazegraph/war/WEB-INF/override-web.xml
#ENV JETTY_OVERRIDEWEBXML=${BLZG_HOME}/conf/web.xml

#### (Java option - Max Memory Usage): 
ARG JAVA_XMX=${JAVA_XMX:-"-Xmx4g"}
ENV JAVA_XMX=${JAVA_XMX:-"-Xmx4g"}

#### (blazegraph option): 
## -Dcom.bigdata.journal.AbstractJournal.file=/data/blazegraph.jnl
## DATA_DIR=${BLZG_HOME}/data
# com.bigdata.journal.AbstractJournal.file=blazegraph.jnl
ARG DATA_DIR=${DATA_DIR:-${BLZG_HOME}/data}
ENV DATA_DIR=${DATA_DIR}

#### (Java option) 
## ARG JAVA_OPTS=${JAVA_OPTS:-Djava.awt.headless=true -Djetty.overrideWebXml=${JETTY_OVERRIDEWEBXML} -Dbigdata.propertyFile=${BIGDATA_PROPERTY} -Dcom.bigdata.journal.AbstractJournal.file=/data/blazegraph.jnl -server -Xmx4g -XX:MaxDirectMemorySize=3000m -XX:+UseG1GC}
## ARG JAVA_OPTS=${JAVA_OPTS:-Djava.awt.headless=true -Dbigdata.propertyFile=${BIGDATA_PROPERTY} -server -Xmx4g -XX:MaxDirectMemorySize=3000m -XX:+UseG1GC}
#ARG JAVA_OPTS=${JAVA_OPTS:-"-Djava.awt.headless=true -Dcom.bigdata.rdf.store.AbstractTripleStore.textIndex=true -server ${JAVA_XMX} -XX:MaxDirectMemorySize=3000m -XX:+UseG1GC"}
#ENV JAVA_OPTS=${JAVA_OPTS:-"-Djava.awt.headless=true -Dcom.bigdata.rdf.store.AbstractTripleStore.textIndex=true -server ${JAVA_XMX} -XX:MaxDirectMemorySize=3000m -XX:+UseG1GC"}

## ----------------------------------------------------------------------------------- ##
## ----------------------------------------------------------------------------------- ##
## ----------- Don't change below unless Product download system change -------------- ##
## ----------------------------------------------------------------------------------- ##
## ----------------------------------------------------------------------------------- ##
## -- Product TAR/GZ filename: -- ##
ARG PRODUCT_TAR=${PRODUCT_TAR:-${PRODUCT_NAME}.tar.gz}

## -- Product Download route: -- ##
ARG PRODUCT_DOWNLOAD_ROUTE=${PRODUCT_DOWNLOAD_ROUTE:-${PRODUCT_PROVIDER}/${PRODUCT_TYPE}/${PRODUCT_VERSION}}

## -- Product Download full URL: -- ##
ARG PRODUCT_DOWNLOAD_URL=${PRODUCT_DOWNLOAD_URL:-${PRODUCT_MIRROR_SITE_URL}/${PRODUCT_DOWNLOAD_ROUTE}}

WORKDIR ${PRODUCT_INSTALL_ROOT_DIR}

RUN \
    wget -c --no-check-certificate ${PRODUCT_DOWNLOAD_URL}/${PRODUCT_TAR} && \
    tar xvf ${PRODUCT_TAR} && \
    mv ${PRODUCT_NAME}-tgz-${PRODUCT_VERSION} ${PRODUCT_NAME} && \
    rm -f ${PRODUCT_TAR} 

RUN \
    mv ${BIGDATA_PROPERTY} ${BIGDATA_PROPERTY}.ORIG && \
    ## (not exist yet) mv war/WEB-INF/GraphStore.properties /war/WEB-INF/GraphStore.properties && \
    ## (not exist yet) mv war/WEB-INF/RWStore.properties war/WEB-INF/RWStore.properties.OIRG && \
    ## (not exist yet) mv ${BLZG_HOME}/war/WEB-INF/classes/RWStore.properties ${BLZG_HOME}/war/WEB-INF/classes/RWStore.properties.ORIG && \
    mv ${PRODUCT_FULL_PATH_EXE} ${PRODUCT_FULL_PATH_EXE}.ORIG 

##################################
#### Install Libs or Plugins  ####
##################################
# (debug use only) 
# ... add Product plugin if any 
RUN \
    apt-get update -y && \
    apt-get install -y sudo ack-grep && \
    rm -rf /var/lib/apt/lists/*

#### ------------------------ ####
#### ---- Blazegraph Override ----
#### ------------------------ ####
## /opt/blazegraph/conf/RWStore.properties
COPY ./override/RWStore.properties ${BIGDATA_PROPERTY}
COPY ./override/log4j.properties ${BLZG_HOME}/war/WEB-INF/classes/log4j.properties
COPY ./override/RWStore.properties ${BLZG_HOME}/war/WEB-INF/classes/RWStore.properties
COPY ./override/RWStore.properties ${BLZG_HOME}/war/WEB-INF/RWStore.properties
#COPY ./override/RWStore.properties ${BLZG_HOME}/war/WEB-INF/GraphStore.properties
COPY ./override/GraphStore.properties ${BLZG_HOME}/war/WEB-INF/GraphStore.properties
COPY ./override/blazegraph.sh ${PRODUCT_FULL_PATH_EXE}
COPY ./rdf-samples ${PRODUCT_HOME}/
COPY ./docker-entrypoint.sh /

################################
#### ---- user: Non-root   ----
################################
## ---- user: developer ----
ENV USER_NAME=blgz
ENV HOME=/home/${USER_NAME}

ARG USER_ID=${USER_ID:-1000}
ENV USER_ID=${USER_ID}

ARG GROUP_ID=${GROUP_ID:-1000}
ENV GROUP_ID=${GROUP_ID}

RUN groupadd -g ${GROUP_ID} ${USER_NAME} && \
    useradd -d ${HOME} -s /bin/bash -u ${USER_ID} -g ${USER_NAME} ${USER_NAME} && \
    usermod -aG root ${USER_NAME} && \
    export uid=${USER_ID} gid=${GROUP_ID} && \
    mkdir -p ${HOME}

#################################
#### Set up run environments ####
#################################
ARG PRODUCT_PROFILE=${PRODUCT_PROFILE:-${HOME}/.${PRODUCT_NAME}-${PRODUCT_VERSION}}

RUN mkdir -p ${PRODUCT_WORKSPACE} ${PRODUCT_PROFILE} ${PRODUCT_DATA} ${DATA_DIR} && \
    chown -R ${USER_NAME}:${USER_NAME} ${BLZG_HOME} ${HOME} /docker-entrypoint.sh && \
    chmod -R 0755 ${BLZG_HOME} && \
    chmod -R 0777 ${BLZG_HOME}/log && \
    chmod 0755 /docker-entrypoint.sh

VOLUME ${PRODUCT_PROFILE} 
VOLUME ${PRODUCT_WORKSPACE}
VOLUME ${PRODUCT_DATA}
VOLUME ${DATA_DIR}

ARG PRODUCT_PORTS=${PRODUCT_PORTS:-9999}
EXPOSE ${PRODUCT_PORTS}

#####################################
#### ---- Start Application ---- ####
#####################################

USER ${USER_NAME}

WORKDIR ${PRODUCT_HOME}
#WORKDIR ${HOME}

#CMD ["/bin/bash", "-c", "${PRODUCT_FULL_PATH_EXE}","start"]
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]

# -- debug only --
#ENTRYPOINT ["/bin/bash"]
