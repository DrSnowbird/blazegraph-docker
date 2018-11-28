# !!!!!!!! NOT-READY-for-Public-Consumption Yet - in testing mode !!!!!!!!!!

# BlazeGraph Server 2.1.4 + Java 8 (1.8.0_191) JDK + Maven 3.5 + Python 3.5 +  Gradle 4.9 + X11 (display GUI)
[![](https://images.microbadger.com/badges/image/openkbs/jdk-mvn-py3-x11.svg)](https://microbadger.com/images/openkbs/blazegraph-docker "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/openkbs/blazegraph-docker.svg)](https://microbadger.com/images/openkbs/blazegraph-docker "Get your own version badge on microbadger.com")

# License Agreement
By using this image, you agree the [Oracle Java JDK License](http://www.oracle.com/technetwork/java/javase/terms/license/index.html).
This image contains [Oracle JDK 8](http://www.oracle.com/technetwork/java/javase/downloads/index.html). You must accept the [Oracle Binary Code License Agreement for Java SE](http://www.oracle.com/technetwork/java/javase/terms/license/index.html) to use this image.

# Components
* [BlazeGraph](https://www.blazegraph.com/) 2.1.4 service will be running at http://<server_ip:9999>/
* java version "1.8.0_191"
  Java(TM) SE Runtime Environment (build 1.8.0_191-b12)
  Java HotSpot(TM) 64-Bit Server VM (build 25.191-b12, mixed mode)
* Apache Maven 3.5.3
* Python 3.5.2
* Other tools: git wget unzip vim python python-setuptools python-dev python-numpy 
* X11 display desktop

# BlazeGraph Server 2.1.4 + Java 8 (1.8.0_181) JDK + Maven 3.5 + Python 3.5
[![](https://images.microbadger.com/badges/image/openkbs/blazegraph.svg)](https://microbadger.com/images/openkbs/blazegraph "Get your own image badge on microbadger.com") [![](https://images.microbadger.com/badges/version/openkbs/blazegraph.svg)](https://microbadger.com/images/openkbs/blazegraph "Get your own version badge on microbadger.com")

# Run (recommended for easy-start)
Image is pulling from openkbs/netbeans
```
./run.sh
```
A successfully starting of BlazeGraph will have the following message displayed (IP address below will be different):
```
Welcome to the Blazegraph(tm) Database.
Go to http://172.17.0.3:9999/blazegraph/ to get started.
```

# Deployment
**Kubernetes / Minikube**: Tested Ok: 
```
(Using Minikube's Web UI Dashboard http://192.168.99.102) -> Deployments -> "CREATE AN APP"
To use non-default (1GB) memory for JVM, add the run-time env vars in the configuration
    JVM_MEM=4g
```
**Openshift / Minishift**: Tested Ok: 
```
(Using OpenShift's Web UI) -> Deployments, then Create Route to expose to external Access.
```
**Portainer / Localhost**: Tested OK: 
```
Using "./run.sh"
To use non-default (1GB) memory for JVM, add entry to "docker.env" file
  JVM_MEM=4g
```
**Docker-compose**:
```
To use non-default (1GB) memory for JVM, add/change entry to "docker-compose.yml" file:
      - JVM_MEM=4g
```
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
```
# Run Blazegraph web, sparql, REST
For more information, please visit: https://wiki.blazegraph.com/wiki/index.php/NanoSparqlServer 

Web UI:
```http
Web UI: http://<ip_address>:9999/
```

For SPARQL Endpoint, see more at https://wiki.blazegraph.com/wiki/index.php/REST_API#SPARQL_End_Point
```http
SPARQL UI: http://<ip_address>:9999/bigdata
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


# Reference
* [BlazeGraph](https://www.blazegraph.com/)
* [FullTextSearch](https://wiki.blazegraph.com/wiki/index.php/FullTextSearch)
