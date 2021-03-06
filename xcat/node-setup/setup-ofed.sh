#!/bin/bash
##########################################################################
### J. Farran
### OFED Mellanox Setup.
### It is assumed that NO IB mounts are in place since we cannot update
### OFED with IB mounted file-system.
###
### This script SHOULD NOT BE RAN ON A NODE WITH JOBS.
### -------------------------------------------------

if [ ! -e /sbin/lspci ];then
    printf "\n ---> Missing /sbin/lspci.   Installing/\n\n"
    /usr/bin/yum -y install pciutils  
fi

HOST=`hostname`
INFINIBAND=`/sbin/lspci | fgrep "Mellanox"`

if [ ! "$INFINIBAND" ];then
    printf "\n ---> Node [ `hostname -s` ] does not have Infiniband - Cannot setup OFED.\n\n"
    exit
fi

CARD_TYPE=`/sbin/lspci | fgrep "MT26428"`
if [ "$CARD_TYPE" ];then
    printf "\n ---> Node [ `hostname -s` ] has Mellanox card no longer supported - Cannot setup OFED.\n\n"
    exit
fi

echo " "

FLAG=/root/setup-ofed-4.3-1.0.1.0.flag
if [ -e $FLAG ];then
    printf "\n Node [ `hostname` already been upgraded to lastest OFED.\n Flag: $FLAG\n Exiting.\n\n"
    exit
fi

/usr/bin/yum -y install lsof tcsh   # Making sure we have these dependicies.  

KERNEL="3.10.0-693.el7.x86_64"
CHECK=`/bin/uname -r`
if [ "$CHECK" = "$KERNEL" ];then
    ISO="/data/xcat/node-setup/node-files/OFED/HPC-OFED_LINUX-4.3-1.0.1.0-rhel7.4-x86_64-ext.iso"
else
    printf "\n ---> Wrong Kernel on [ `hostname -s` ]\n"
    printf "\n ---> We need [ $KERNEL ].  Node has [ $CHECK ]\n Exiting.\n\n"
    exit
fi

printf "\n ---> Kernel check PASS.\n\n"

printf " ------------------------------------------------\n"
printf " Setting up OFED on `hostname`\n"
printf " ------------------------------------------------\n"

/sbin/service ibacm        stop
/sbin/service opensmd      stop
/sbin/service openibd      stop
/sbin/service fca_managerd stop

# Install needed bits
yum install -y "*hwloc*"

printf "\n ---> Installing Mellanox OFED.\n\n"

/bin/mount -o ro,loop $ISO /mnt

echo "Y" | /mnt/mlnxofedinstall
/bin/umount /mnt

printf " ---> Starting Infiniband network.\n\n"
/sbin/service openibd restart

printf "\n --> Removing mpi-selector and other MPI software that comes with Mellanox that we do not use."
/usr/bin/yum -y erase "mpi-selector*"

/bin/rm -f /etc/profile.d/modules.sh
/bin/rm -f /etc/profile.d/modules.csh

/sbin/chkconfig --add openibd
/sbin/chkconfig --add opensmd
/sbin/chkconfig --add ibacm
/sbin/chkconfig --add fca_managerd 

/sbin/chkconfig openibd      on

if [[ "$HOST" =~ "nas-" ]];then
    /sbin/chkconfig opensmd      on
    /sbin/chkconfig ibacm        on
    /sbin/chkconfig fca_managerd on
else
    /sbin/chkconfig opensmd      off
    /sbin/chkconfig ibacm        off
    /sbin/chkconfig fca_managerd off
fi

printf "\n ---> OFED Testing:\n\n"
/usr/bin/hca_self_test.ofed
/etc/infiniband/info

/data/node-setup/setup-hosts.sh

# JF Needs to be redone for xcat
#/data/node-setup/setup-ib0.sh

echo "All done."
/bin/touch $FLAG
