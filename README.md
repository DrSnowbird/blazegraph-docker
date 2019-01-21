# BlazeGraph Server 2.1.4 + Java 8 (1.8.0_201) JDK + Maven 3.6 + Python 3.5 + PIP3 18.1 + + node 11.7.0 + npm 6.5.0 + Gradle 5.1

[![](https://images.microbadger.com/badges/image/openkbs/blazegraph-docker.svg)](https://microbadger.com/images/openkbs/blazegraph-docker "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/openkbs/blazegraph-docker.svg)](https://microbadger.com/images/openkbs/blazegraph-docker "Get your own version badge on microbadger.com")

# License Agreement
By using this image, you agree the [Oracle Java JDK License](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).
This image contains [Oracle JDK 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html). You must accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html) to use this image.

# Use Cases
This Blazegraph server is aiming for deployment over Container Cluster Platform such as Kubernetes, OpenShift, or other similar ones comparing to other light version of [openkbs/blazegrapy](https://hub.docker.com/r/openkbs/blazegraph-docker). In all, this implementation supports the following deployment uses:
- Using ./run.sh or Portainer Container Desktop or other similar for standalone deployment.
- Using 'docker-compose up -d' for standalone deployment.
- Using Kubernetes, Openshift, or other platforms for cloud / cluster deployment.

# Security
* Non-root user for container:
  We are tightening down the security of containerfor this container, we use non-root user (blzg as user) to run the Blazegraph. 
* Though, currently, you can go into container to use "sudo" to do admin work. 
  For production deployment, we recommend to remove sudo access inside container and other vulnerability codes. At this point, we are still relative relaxing in not fully locking down security yet.

# Components
* [BlazeGraph](https://www.blazegraph.com/) 2.1.4 service will be running at http://<server_ip:9999>/
* java version "1.8.0_201"
  Java(TM) SE Runtime Environment (build 1.8.0_201-b09)
  Java HotSpot(TM) 64-Bit Server VM (build 25.201-b09, mixed mode)
* Apache Maven 3.6.0
* Python 3.5.2
* node v11.7.0 + npm 6.5.0 (from NodeSource official Node Distribution)
* Gradle 5.1
* Other tools: git wget unzip vim python python-setuptools python-dev pandas python-numpy 

# Run (recommended for easy-start)
Image is pulling from openkbs/blazegraph
```
./run.sh
```
A successfully starting of BlazeGraph will have the following message displayed (IP address below will be different):
```
Welcome to the Blazegraph(tm) Database.
Go to http://<ip_address>:9999/blazegraph/ to get started.
```

# Run (manually)
The following example shows customized command to launch container:
```
docker run --rm -d --name=blazegraph-docker --restart=no \
    --user 1000 \ 
    -v /home/user1/data-docker/blazegraph-docker/data:/var/lib/blazegraph/data \
    -v /home/user1/data-docker/blazegraph-docker/.java:/home/developer/.java \
    -v /home/user1/data-docker/blazegraph-docker/.profile:/home/developer/.profile \
    -p 9999:9999 \
    openkbs/blazegraph-docker
```
# Demo
To demonstrate the Blazegraph with FreeText Search capability as powerful combination with RDF/Sparql query/search, you can load the "Hello.rdf" using the following steps after you login to Openshift/Minishift Web UI:
```
First, Create Project, say, ["semantics-engine"], then
click [UPDATE] tab 
    -> select [Choose File] button at lower-left corner
        -> pick "blazegraph-docker/rdf-samples/Hello.rdf" from the pop-up file chooser, then click OK/done
    -> click [Update] button at the lower center of the screen.
... You will see it is loading up the "Hello.rdf" file into Blazegraph database.
click upper-right corner [SEARCH], then type "web" then return key or hit magnify lens icon.
... You will see it returns one tuple of "www.w3schools.com" with subject.
... Congratulation! You have successfully launched, loaded, and tested the powerful RDF/FreeText Search Engine/Database - "Blazegraph"!
```
# Deployment
## Kubernetes / Minikube 
See [docs/Kubernetes-Dashboard-Deploy-Services.png](https://github.com/DrSnowbird/blazegraph-docker/blob/master/docs/Kubernetes-Dashboard-Deploy-Services.png) and [doc/Kubernetes-Dashboard-UI.png ](https://github.com/DrSnowbird/blazegraph-docker/blob/master/docs/Kubernetes-Dashboard-UI.png).
```
(Using Minikube's Web UI Dashboard http://192.168.99.102) -> "+CREATE" -> "CREATE AN APP"
To use non-default (1GB) memory for JVM, add the run-time env vars in the configuration, e.g. 4 GB Memory
    JVM_MEM=4g
```
Then, you will access Blazegraph Docker container like the following except port will be different for yours:
```
http://192.168.99.100:32721/blazegraph/
```
## Openshift / Minishift 
See [docs/OpenShift-blazegraph-docker-deployment.png](https://github.com/DrSnowbird/blazegraph-docker/blob/master/docs/OpenShift-blazegraph-docker-deployment.png).
```
(Using OpenShift's Web UI) -> Deploy -> Image, wait a few seconds for docker pod to up, then Create Route to expose to external Access.
```
## Portainer as Desktop
See [docs/Portainer-as-Docker-Desktop.png](https://github.com/DrSnowbird/blazegraph-docker/blob/master/docs/Portainer-as-Docker-Desktop.png).
```
Using "./run.sh"
```
## Docker-compose
```
To use non-default (e.g., 4GB) memory for JVM, add/change entry to "docker-compose.yml" file:
      - JVM_MEM=4g
```

# Data Persistence
At this point, we only provide default host-based volume mapping persistence 
```
(from file ./docker.env -- the "#" with no space is how "run.sh" pick up the volumes mapping you specify)
#VOLUMES_LIST="data:/var/lib/blazegraph/data .java .profile"
```
Then, running "**./run.sh**" will use the "docker.env" file's entry (as above) to create volume mapping
```
-v /home/<Your UserName>/data-docker/blazegraph-docker/data:/var/lib/blazegraph/data
```
# Distributed Data Persistence
* Currently, we are working on the distributed data/file persistence solution using such as Gluster, Lustre, BeeGFS, etc. However, before we provide the cluster-enabled distributed persistence implementation, please use the above host-based volume mapping solution.
* When deploying to OpenShift, Mesos, DC/OS, etc., you can use "envrionment parameter to create your own host-based file mapping instead of default.

# Build
You can build your own image locally.
```
./build.sh
```

# Build / Run your own image

Say, you will build the image "my/blazegraph".

```bash
docker build -t my/blazegraph .
```

To run your own image, say, with some-blazegraph:

```bash
mkdir ./data
docker run -d --name some-blazegraph -v $PWD/data:/data -i -t my/blazegraph
```

# Shell into the Docker instance
```bash
docker exec -it some-blazegraph /bin/bash
or 
./shell.sh (if you use default ./run.sh -- not your local build)
```

# Web UI
```http
Web UI: http://<ip_address>:9999/
```

# Blazegraph Sparql, REST
For more information, please visit: 
* https://wiki.blazegraph.com/wiki/index.php/NanoSparqlServer 
For SPARQL Endpoint, see more at 
* https://wiki.blazegraph.com/wiki/index.php/REST_API#SPARQL_End_Point

To use SPARQL REST API, from remote SPARQL Client:
```http
http://<ip_address>:9999/bigdata
```

# (Optional Use) Run Python code
To run Python code 

```bash
docker run --rm openkbs/blazegraph python -c 'print("Hello World")'
```

or,

```bash
mkdir ./data
echo "print('Hello World')" > ./data/myPyScript.py
docker run -it --rm --name some-blazegraph -v "$PWD"/data:/data openkbs/blazegraph python myPyScript.py
```

or,

```bash
alias dpy='docker run --rm openkbs/blazegraph python'
dpy -c 'print("Hello World")'
```
# (Optional Use) Compile or Run java while no local installation needed
Remember, the default working directory, /data, inside the docker container -- treat is as "/".
So, if you create subdirectory, "./data/workspace", in the host machine and
the docker container will have it as "/data/workspace".

```java
#!/bin/bash -x
mkdir ./data
cat >./data/HelloWorld.java <<-EOF
public class HelloWorld {
   public static void main(String[] args) {
      System.out.println("Hello, World");
   }
}
EOF
cat ./data/HelloWorld.java
alias djavac='docker run -it --rm --name some-jre-mvn-py3 -v '$PWD'/data:/data openkbs/jre-mvn-py3 javac'
alias djava='docker run -it --rm --name some-jre-mvn-py3 -v '$PWD'/data:/data openkbs/jre-mvn-py3 java'

djavac HelloWorld.java
djava HelloWorld
```
And, the output:
```
Hello, World
```
Hence, the alias above, "djavac" and "djava" is your docker-based "javac" and "java" commands and
it will work the same way as your local installed Java's "javac" and "java" commands.

# Related Tools
* [OpenKBS/blazegraph-docker](https://github.com/DrSnowbird/blazegraph-docker) - Blazegraph RDF Database Engine (CPU + GPU)
* [Google Refine w/RDF Extension](https://github.com/DrSnowbird/grefine-rdf-extension) - Google Refine with RDF Extension
* [OpenKBS/GraphDB-Docker](https://github.com/DrSnowbird/graphdb) - Ontotext GraphDB / RDF Platform
* [Docker-based Stanford Protege (RDF/OWL) IDE](https://hub.docker.com/r/openkbs/protege-docker)
* [Web-based Protege Docker by openkbs/docker-webprotege](https://hub.docker.com/r/openkbs/docker-webprotege/)
* [big-data-europe/docker-kafkasail](https://github.com/big-data-europe/docker-kafkasail) - Apache Tomcat with OpenRDF's (rdf4j) openrdf-workbench and openrdf-sesame server Apache Tomcat with OpenRDF's (rdf4j) openrdf-workbench and openrdf-sesame server 
* [yyz1989/docker-rdf4j](https://github.com/yyz1989/docker-rdf4j) - RDF4J Server (which is RDF database server and the SPARQL endpoint service) and RDF4J Workbench (which is the Web UI of RDF4J Server for database and data management tasks)

# References
* [Stanford Protege](https://protege.stanford.edu/)
* [RDF4J (Java RDF)](http://rdf4j.org/)
* [Semantic Analytics Stack (SANSA)](http://sansa-stack.net/) - Big Data Analytics + Semantic Technology Stacks
* [FullTextSearch](https://wiki.blazegraph.com/wiki/index.php/FullTextSearch)
* [BlazeGraph](https://www.blazegraph.com/)

# Releases information
```
blzg@7d33be3b1509:/var/lib/blazegraph$ /usr/printVersions.sh 
+ echo JAVA_HOME=/usr/java
JAVA_HOME=/usr/java
+ java -version
java version "1.8.0_201"
Java(TM) SE Runtime Environment (build 1.8.0_201-b09)
Java HotSpot(TM) 64-Bit Server VM (build 25.201-b09, mixed mode)
+ mvn --version
Apache Maven 3.6.0 (97c98ec64a1fdfee7767ce5ffb20918da4f719f3; 2018-10-24T18:41:47Z)
Maven home: /usr/apache-maven-3.6.0
Java version: 1.8.0_201, vendor: Oracle Corporation, runtime: /usr/jdk1.8.0_201/jre
Default locale: en_US, platform encoding: ANSI_X3.4-1968
OS name: "linux", version: "4.15.0-43-generic", arch: "amd64", family: "unix"
+ python -V
Python 2.7.12
+ python3 -V
Python 3.5.2
+ pip --version
pip 18.1 from /usr/local/lib/python3.5/dist-packages/pip (python 3.5)
+ pip3 --version
pip 18.1 from /usr/local/lib/python3.5/dist-packages/pip (python 3.5)
+ gradle --version

Welcome to Gradle 5.1.1!

Here are the highlights of this release:
 - Control which dependencies can be retrieved from which repositories
 - Production-ready configuration avoidance APIs

For more details see https://docs.gradle.org/5.1.1/release-notes.html


------------------------------------------------------------
Gradle 5.1.1
------------------------------------------------------------

Build time:   2019-01-10 23:05:02 UTC
Revision:     3c9abb645fb83932c44e8610642393ad62116807

Kotlin DSL:   1.1.1
Kotlin:       1.3.11
Groovy:       2.5.4
Ant:          Apache Ant(TM) version 1.9.13 compiled on July 10 2018
JVM:          1.8.0_201 (Oracle Corporation 25.201-b09)
OS:           Linux 4.15.0-43-generic amd64

+ npm -v
6.5.0
+ node -v
v11.7.0
+ cat /etc/lsb-release /etc/os-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.3 LTS"
NAME="Ubuntu"
VERSION="16.04.3 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.3 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial
```
