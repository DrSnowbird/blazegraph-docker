# BlazeGraph Server 2.1.5 + OpenJDK Java 8 JDK + Maven 3.6 + Python 3.6/2.7 + pip 20 + node 15 + npm 7 + Gradle 6

[![](https://images.microbadger.com/badges/image/openkbs/blazegraph-docker.svg)](https://microbadger.com/images/openkbs/blazegraph-docker "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/openkbs/blazegraph-docker.svg)](https://microbadger.com/images/openkbs/blazegraph-docker "Get your own version badge on microbadger.com")

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
* [BlazeGraph](https://www.blazegraph.com/) 2.1.5 service will be running at http://<server_ip:9999>/
* Ubuntu 18.04 LTS now (soon will use Ubuntu 20.04 as LTS Docker base image).
* See [openkbs/jdk-mvn-py3 README.md](https://github.com/DrSnowbird/jdk-mvn-py3/blob/master/README.md)
* See [Base Container Image: openkbs/jdk-mvn-py3](https://github.com/DrSnowbird/jdk-mvn-py3)
* See [Base Components: OpenJDK, Python 3, PIP, Node/NPM, Gradle, Maven, etc.](https://github.com/DrSnowbird/jdk-mvn-py3#components)
* Other tools: git wget unzip vim python python-setuptools python-dev python-numpy, ..., etc.

# Persistence
1. Using 'docker-compose up -d' will use Docker's volume to persist across multiple delete/create Docker container unless you change the volume name in 'docker-compose.yaml' file. Or, you intentionally use 'docker-compose down -v' to remove the volume and you will lost your previous data stored using Blazegraph.
2. Using 'run.sh' will use the same Docker's volume as using 'docker-compose.yaml' since both of them using the same volume name.

# Run (recommended for easy-start)
Image is pulling from openkbs/blazegraph
```
./run.sh
```
A successfully starting of BlazeGraph will allow you to access the following URL:
```
    http://<ip_address>:9999/blazegraph/ to get started.
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
* [See Releases Information](https://github.com/DrSnowbird/jdk-mvn-py3#releases-information)

