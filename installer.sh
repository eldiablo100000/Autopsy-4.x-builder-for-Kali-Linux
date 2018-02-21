#!/bin/bash

workingdir=`pwd`

echo deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main >> /etc/apt/sources.list

echo deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu precise main >> /etc/apt/sources.list


echo ---INSTALLING ADD-APT-REPOSITORY AND ADDING JAVA8 REPOSITORY---
wget http://blog.anantshri.info/content/uploads/2010/09/add-apt-repository.sh.txt
mv add-apt-repository.sh.txt /usr/sbin/add-apt-repository
chmod o+x /usr/sbin/add-apt-repository
chown root:root /usr/sbin/add-apt-repository
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update

echo ---------APT GET INSTALL---------
sudo apt-key adv –keyserver keyserver.ubuntu.com –recv-keys EEA14886

sudo apt-get update

sudo apt-get install -y rename build-essential debhelper fakeroot pkg-config autotools-dev zlib1g-dev bzip2 libssl-dev libfuse-dev python-all-dev python3-all-dev software-properties-common wget xauth git git-svn build-essential libssl-dev libbz2-dev libz-dev ant automake autoconf libtool vim python-dev uuid-dev libfuse-dev libcppunit-dev libafflib-dev gstreamer1.0 oracle-java8-installer software-properties-common wget xauth git git-svn build-essential libssl-dev libbz2-dev libz-dev ant automake autoconf libtool vim python-dev gstreamer1.0 oracle-java8-set-default
#all gstreamer1-0 packets excepted the dbg files, to avoid 'unmet dependencies' of APT
sudo apt-get install -y gstreamer1.0-alsa gstreamer1.0-clutter-3.0 gstreamer1.0-crystalhd gstreamer1.0-doc gstreamer1.0-espeak gstreamer1.0-fluendo-mp3 gstreamer1.0-libav gstreamer1.0-nice gstreamer1.0-omx-bellagio-config gstreamer1.0-omx-generic gstreamer1.0-omx-generic-config gstreamer1.0-packagekit gstreamer1.0-plugins-bad gstreamer1.0-plugins-bad-doc gstreamer1.0-plugins-base gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-base-doc gstreamer1.0-plugins-good gstreamer1.0-plugins-good-doc gstreamer1.0-plugins-ugly gstreamer1.0-plugins-ugly-doc gstreamer1.0-pocketsphinx gstreamer1.0-pulseaudio gstreamer1.0-python3-plugin-loader gstreamer1.0-rtsp gstreamer1.0-tools gstreamer1.0-vaapi gstreamer1.0-vaapi-doc gstreamer1.0-x 
sudo apt-get update
echo ---------MKDIR TSK---------
mkdir -p $workingdir/tsk/bindings/java/dist
mkdir -p $workingdir/tsk/bindings/java/lib
echo ---------EXPORT---------
export JAVA_HOME="/usr/lib/jvm/java-8-oracle/"
export JDK_HOME="/usr/lib/jvm/java-8-oracle/"
export JRE_HOME="/usr/lib/jvm/java-8-oracle/jre/"
export TSK_HOME=$workingdir/tsk
echo $JAVA_HOME
echo $JDK_HOME
echo $JRE_HOME
echo $TSK_HOME
# Download files / Git Reps
echo ---------SLEUTHKIT---------
if [ ! -d sleuthkit ]; then
git clone https://github.com/sleuthkit/sleuthkit.git
fi
cd sleuthkit
make clean
git pull
cd ..
echo ---------AUTOPSY---------
if [ ! -d autopsy ]; then
git clone https://github.com/sleuthkit/autopsy.git
fi
cd autopsy
make clean
git pull
cd ..
echo ---------LIBEWF---------
if [ ! -d libewf ]; then
git clone https://github.com/libyal/libewf.git
fi
cd libewf
make clean
git pull
cd ..
# Compile libewf
echo ---------COMPILE LIBEWF---------
cd $workingdir/libewf
./synclibs.sh
./autogen.sh
./configure -enable-python -enable-verbose-output -enable-debug-output -prefix=$workingdir/tsk
make 
sudo make install

# Compile Sleuthkit
echo ---------COMPILE SLEUTHKIT---------
cd $workingdir/sleuthkit

sed -i 's/libewf_handle_read_random/libewf_handle_read_buffer_at_offset/g' $workingdir/sleuthkit/tsk/img/ewf.c
./bootstrap
./configure -prefix=$workingdir/tsk -with-libewf=$workingdir/tsk
make
sudo make install

#export TSK_HOME=$workingdir/tsk

# Build autopsy
echo ---------BUILD AUTOPSY---------
sed -i 's=deadlock.netbeans.org/hudson/job/nbms-and-javadoc/lastStableBuild/artifact/nbbuild/netbeans/harness/tasks.jar=bits.netbeans.org/dev/nbms-and-javadoc/lastSuccessfulBuild/artifact/nbbuild/netbeans/harness/tasks.jar=' $workingdir/autopsy/nbproject/platform.properties
if ls $workingdir/tsk/share/java/sleuthkit-postgresql-*jar 1> /dev/null 2>&1; then
    echo "files do exist"
else
	rename  's/sleuthkit/sleuthkit-postgresql/g' $workingdir/tsk/share/java/*jar
fi
if ls $workingdir/tsk/bindings/java/dist/sleuthkit-postgresql-*jar 1> /dev/null 2>&1; then
	echo "files do exist"
else
	cp $workingdir/tsk/share/java/* $workingdir/tsk/bindings/java/dist/
fi
if ls $workingdir/autopsy/Core/tsk/bindings/java/dist/sleuthkit-postgresql-*jar 1> /dev/null 2>&1; then
	echo "files do exist"
else
	cp $workingdir/tsk/share/java/* $workingdir/autopsy/Core/tsk/bindings/java/dist/
fi


cd $workingdir/tsk/bindings/java/lib
wget -c https://repo1.maven.org/maven2/org/xerial/sqlite-jdbc/3.7.15-M1/sqlite-jdbc-3.7.15-M1.jar
cp $workingdir/sleuthkit/bindings/java/lib/* ./

cd $workingdir/autopsy
ant build
echo ---------RUN INSTALL---------

ant run

