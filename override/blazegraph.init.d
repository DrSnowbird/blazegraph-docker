#!/bin/sh
#
# /etc/init.d/blazegraph -- startup script for Blazegraph
#
# chkconfig: 2345 65 25
# description:  Blazegraph High Performance Graph Database
#
# processname: blazegraph
# config: /etc/blazegraph/blazegraph
# pid:  /var/run/blazegraph.pid
#
# Modified from the tomcat7 script
# Written by Miquel van Smoorenburg <miquels@cistron.nl>.
# Modified for Debian GNU/Linux    by Ian Murdock <imurdock@gnu.ai.mit.edu>.
# Modified for Tomcat by Stefan Gybas <sgybas@debian.org>.
# Modified for Tomcat6 by Thierry Carrez <thierry.carrez@ubuntu.com>.
# Modified for Tomcat7 by Ernesto Hernandez-Novich <emhn@itverx.com.ve>.
# Additional improvements by Jason Brittain <jason.brittain@mulesoft.com>.
# Modified for Blazegraph by Brad Bebee <beebs@systap.com>
#
### BEGIN INIT INFO
# Provides:          blazegraph
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs $network
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start Blazegraph
# Description:       Start the Blazegraph High Performance Database.
### END INIT INFO

# source function library
. /etc/rc.d/init.d/functions

PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ `id -u` -ne 0 ]; then
    echo "You need root privileges to run this script"
    exit 1
fi
 
# Make sure blazegraph is started with system locale
if [ -r /etc/default/locale ]; then
    . /etc/default/locale
    export LANG
fi


NAME="$(basename $0)"

NAME=blazegraph
DESC="Blazegraph High Performance Database"

#Modify this value to the current location of your conf/blazegraph.
#You may also create a symbolic link to to /etc/blazegraph/blazegraph.
DEFAULT=/etc/${NAME}/$NAME
JVM_TMP=/tmp/blazegraph-$NAME-tmp

unset ISBOOT
if [ "${NAME:0:1}" = "S" -o "${NAME:0:1}" = "K" ]; then
    NAME="${NAME:3}"
    ISBOOT="1"
fi

# For SELinux we need to use 'runuser' not 'su'
if [ -x "/sbin/runuser" ]; then
    SU="/sbin/runuser -s /bin/sh"
else
    SU="/bin/su -s /bin/sh"
fi


# The following variables can be overwritten in $DEFAULT

# this is a work-around until there is a suitable runtime replacement 
# for dpkg-architecture for arch:all packages
# this function sets the variable OPENJDKS
find_openjdks()
{
    if [ -z "${JAVA_HOME}" ]; then
        jdkVersions="10 9 8 7"
        found=0
        for v in $jdkVersions; do
            for jvmdir in /usr/lib/jvm/java-${version}-openjdk-*
            do
                if [ -d "${jvmdir}" -a "${jvmdir}" != "/usr/lib/jvm/java-${version}-openjdk-common" ]
                then
                    OPENJDKS=$jvmdir
                    export JAVA_HOME=$jvmdir
                    found=1
                fi
            done
            if [ $found -gt 0 ]; then
                break;;
            fi
        done
    fi
}

#### ---- commented out by DrSnowbird/OpenKBS
#OPENJDKS=""
#find_openjdks
## The first existing directory is used for JAVA_HOME (if JAVA_HOME is not
## defined in $DEFAULT)
#JDK_DIRS="/usr /usr/lib/jvm/java-7-oracle usr/lib/jvm/default-java ${OPENJDKS} /usr/lib/jvm/java-6-openjdk /usr/lib/jvm/java-6-sun"

## Look for the right JVM to use
#for jdir in $JDK_DIRS; do
#    if [ -r "$jdir/bin/java" -a -z "${JAVA_HOME}" ]; then
#    JAVA_HOME="$jdir"
#    fi
#done
echo "JAVA_HOME=$JAVA_HOME"
export JAVA_HOME

# Directory where the Blazegraph distribution resides
if [ -z "$BLZG_HOME" ] ; then
    BLZG_HOME=/usr/local/$NAME
fi

# Directory for per-instance configuration files and webapps
if [ -z "${BLZG_BASE}" ] ; then
    BLZG_BASE=$BLZG_HOME
fi

# Use the Java security manager? (yes/no)
BLZG_SECURITY=no

# Default Java options
# Set java.awt.headless=true if JAVA_OPTS is not set so the
# Xalan XSL transformer can work without X11 display on JDK 1.4+
# It also looks like the default heap size of 64M is not enough for most cases
# so the maximum heap size is set to 128M
if [ -z "$JAVA_OPTS" ]; then
    JAVA_OPTS="-Djava.awt.headless=true -Xmx128M"
fi

# End of variables that can be overwritten in $DEFAULT

# overwrite settings from default file
if [ -f "$DEFAULT" ]; then
    . "$DEFAULT"
fi

if [ ! -f "$BLZG_HOME/bin/blazegraph.sh" ]; then
    echo "$NAME is not installed"
    exit 1
fi

if [ -z "$BLZG_TMPDIR" ]; then
    BLZG_TMPDIR="$JVM_TMP"
fi

SECURITY=""
if [ "$BLZG_SECURITY" = "yes" ]; then
    SECURITY="-security"
fi

# Define other required variables
BLZG_PID="/var/run/$NAME.pid"
BLZG_SH="$BLZG_HOME/bin/blazegraph.sh"

# Look for Java Secure Sockets Extension (JSSE) JARs
if [ -z "${JSSE_HOME}" -a -r "${JAVA_HOME}/jre/lib/jsse.jar" ]; then
    JSSE_HOME="${JAVA_HOME}/jre/"
fi

blazegraph_sh() {
    # Escape any double quotes in the value of JAVA_OPTS
    JAVA_OPTS="$(echo $JAVA_OPTS | sed 's/\"/\\\"/g')"

    # Define the command to run Tomcat's blazegraph.sh as a daemon
    # set -a tells sh to export assigned variables to spawned shells.
    BLZGCMD_SH="set -a; JAVA_HOME=\"$JAVA_HOME\"; \
        source \"$DEFAULT\"; \
        BLZG_HOME=\"$BLZG_HOME\"; \
        BLZG_BASE=\"$BLZG_BASE\"; \
        JAVA_OPTS=\"$JAVA_OPTS\"; \
        BLZG_PID=\"$BLZG_PID\"; \
        BLZG_LOG=\"$BLZG_LOG\"/blazegraph.out; \
        BLZG_TMPDIR=\"$BLZG_TMPDIR\"; \
        LANG=\"$LANG\"; JSSE_HOME=\"$JSSE_HOME\"; \
        cd \"$BLZG_BASE\"; \
        \"$BLZG_SH\" $@"

    set +e
    touch "$BLZG_PID" "$BLZG_LOG"/blazegraph.out
    chown $BLZG_USER "$BLZG_PID" "$BLZG_LOG"/blazegraph.out
    $SU - $BLZG_USER -c "$BLZGCMD_SH start"
    status="$?"

    if [ $status -gt 0 ] ; then
        PID=`cat $BLZG_PID`
        echo "Started $NAME (pid: $PID)"
    fi

    set +a -e
    return $status
}

running_pid() {

    if [ ! -f "${BLZG_PID}" ] ; then
        return 0;
                exit 0
    fi

    PID=`cat ${BLZG_PID}`

    let HAS_PID=`ps -eo pid | grep $PID | wc -l`

    echo ${HAS_PID}

    return ${HAS_PID} 
    #1 if running, 0 if not

}

case "$1" in
  start)
    if [ -z "$JAVA_HOME" ]; then
        echo "no JDK or JRE found - please set JAVA_HOME"
        exit 1
    fi

    if [ ! -d "$BLZG_BASE/conf" ]; then
        echo "invalid BLZG_BASE: $BLZG_BASE"
        exit 1
    fi

    echo "Starting $DESC" "$NAME"
    # Remove / recreate JVM_TMP directory
    rm -rf "$JVM_TMP"
    mkdir -p "$JVM_TMP" || {
        echo "could not create JVM temporary directory"
        exit 1
    }
    chown $BLZG_USER "$JVM_TMP"
    blazegraph_sh start 

    sleep 5
    ;;
  stop)
    echo "Stopping $DESC" "$NAME"

    set +e
    if [ -f "$BLZG_PID" ]; then 

        PID=`cat "${BLZG_PID}"`    
    
        if [ `running_pid` -eq 1 ] ; then

            kill -9 $PID
            if [ `running_pid` -eq 0 ] ; then
                rm -f "${BLZG_PID}"
                rm -rf "$JVM_TMP"
                echo "Stopped $NAME (pid ${PID})"
            else
                echo "Failed to stop $NAME (pid ${PID})"
            fi
        fi

    else
        echo "(not running)"
    fi
    set -e
    ;;
   status)
    set +e

    if [ -f "${BLZG_PID}" ] &&  [ `running_pid` -eq 0 ]; then
        echo "$DESC is not running, but pid file exists."
        exit 3
    elif [ ! -f "$BLZG_PID" ]; then
        echo "$DESC is not running."
        exit 1
    else
        echo "$DESC is running with pid `cat $BLZG_PID`"
    fi
    set -e
        ;;
  restart|force-reload)
    if [ -f "$BLZG_PID" ]; then
        $0 stop
        sleep 1
    fi
    $0 start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|force-reload|status}"
    exit 1
    ;;
esac

exit 0
