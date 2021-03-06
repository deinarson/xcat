#!/bin/bash
##########################################################################
#### J. Farran
#### Yum packages to install on all Nodes ( yum yum :-)

#need update for prod.
YUMS=/tmp/install/hpc/yums-to-install.txt
YUMS_LOGIN=/data/node-setup/node-files/yums-login-to-install.txt

LOG=/tmp/,yum-to-install.log
HOST=`hostname`

if [[ $HOST = hpc-s.* ]];then
    echo " "
    echo "-----> Do NOT run this on the head node! Exiting."
    exit -1
fi

/bin/rm -f $LOG

/tmp/install/hpc/setup-local-repos.sh &>> $LOG

echo "--------------"   &>> $LOG
echo "Yum Cleanup..."   &>> $LOG
echo "--------------"   &>> $LOG

yum clean all && yum clean metadata && yum clean dbcache && yum makecache  &>> $LOG
yum install yum-utils   &>> $LOG

echo "---------------------------------------------"   &>> $LOG
echo "Problematic Yums to remove before Yum Install"   &>> $LOG
echo "---------------------------------------------"   &>> $LOG
#yum erase foundation-graphviz                          &>> $LOG

# First install the important groups
echo "Installing some critical Yum groups" &>> $LOG
echo "---------------------------------------------"   &>> $LOG
yum groupinstall "Development tools" -y &>> $LOG
yum groupinstall "Additional Development" -y &>> $LOG
yum groupinstall "Compatibility libraries" -y &>> $LOG

echo "" &>> $LOG
echo "Done installing critical groups" &>> $LOG
echo "---------------------------------------------"   &>> $LOG

for package in `/bin/cat $YUMS`
do
    echo "--------------------------------------------------------------------------" &>> $LOG
    echo "------------------------> Installing [ $package ]"                          &>> $LOG
    echo "--------------------------------------------------------------------------" &>> $LOG
    /usr/bin/yum -y install --skip-broken "$package"                                  &>> $LOG
done

echo "Special rpms to install and start:"        &>> $LOG
echo "----------------------------------"        &>> $LOG
/sbin/chkconfig edac on                          &>> $LOG
/sbin/service edac restart                       &>> $LOG                


##########################################################################
#### Login Node

echo " "
if [[  $HOST  =~ "hpc-login-"   ]] || \
    [[ $HOST  =~ "compute-1-13" ]]; then
    
    echo " "                                                          &>> $LOG
    echo "-----> This is a login node.  Additional YUMs to install."  &>> $LOG
    echo "---------------------------------------------------------"  &>> $LOG
    
#    yum -y install gnome-session gnome-session-xsession

    # get the x2go repository set up
#    wget http://download.opensuse.org/repositories/X11:/RemoteDesktop:/x2go/RHEL_6/X11:RemoteDesktop:x2go.repo &>> $LOG
#    /bin/cp X11:RemoteDesktop:x2go.repo /etc/yum.repos.d/x2go.repo &>> $LOG
    
    for package in `/bin/cat $YUMS_LOGIN`
    do
	echo "------------------------------------" &>> $LOG
	echo "--> Installing [ $package ]"          &>> $LOG
	echo "------------------------------------" &>> $LOG
	/usr/bin/yum -y install "$package"          &>> $LOG
    done
    
    yum groupinstall "X Window System"
    yum groupinstall "Development Tools"

    /sbin/chkconfig rsync on                        &>> $LOG
    /sbin/chkconfig nscd  on                        &>> $LOG
fi

##########################################################################
#### Packages Not needed:

echo "Packages NOT needed.  Removing..."          &>> $LOG
echo "---------------------------------"          &>> $LOG

for software in "environment-modules" "cpuspeed" "fftw" "emacs-auto-complete" \
    "R-core" "gnome-screensaver" "gnome-power-manager"  \
    "GE-2011.11p1" "gnome-screensaver" "*bluetooth*"    \
    "pulseaudio-libs";
do
    echo " "                                      &>> $LOG
    echo "------------------------------------"   &>> $LOG
    echo "Removing software: $software"           &>> $LOG
    echo "------------------------------------"   &>> $LOG
    yum erase -y "$software"                      &>> $LOG
done


##########################################################################
#### Final yums to install
#yum install gedit                          &>> $LOG

# Remove stupid config file parallel package installs.
/bin/rm  /etc/parallel/config >& /dev/null

echo " "                                   &>> $LOG
echo "-------------------------------"     &>> $LOG
echo "Yum with problems / duplicates:"     &>> $LOG
echo "-------------------------------"     &>> $LOG

package-cleanup --problems                 &>> $LOG
package-cleanup --dupes                    &>> $LOG

echo "Done."                               &>> $LOG
