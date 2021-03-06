#!/bin/bash
#### J. Farran 2/2016
#### Check that ib0 (if Infiniband ) is setup ok.
#### Simple tests.

if [ ! -e /sbin/lspci ];then
    echo "Cannot continue.  Missing /sbin/lspci.   Exiting..."
    exit
fi

INFINIBAND=''
INFINIBAND=`/sbin/lspci | fgrep "Mellanox"`

if [ ! "$INFINIBAND" ];then
    echo "Node [ `hostname -s` ] does not have Infiniband - Skipping ib0 check."
    
    if [ -e /etc/sysconfig/network-scripts/ifcfg-ib0 ];then
	echo "---> ifcfg-ib0 exists.   Removing."
	/bin/rm -f /etc/sysconfig/network-scripts/ifcfg-ib0
    fi
    exit
else
    echo "Checking [ `hostname -s` ] Infiniband setup."
fi

if [ ! -e /etc/sysconfig/network-scripts/ifcfg-ib0 ];then
    echo "Network ifcfg-ib0 does NOT exists.   Recreating..."
    /data/xcat/node-setup/setup-ib0.sh
    exit
fi

CONNECTED_MODE=`/bin/cat /etc/sysconfig/network-scripts/ifcfg-ib0 | grep "CONNECTED_MODE"`

if [ "$CONNECTED_MODE" ];then
    echo " "
    echo "Node has 'CONNECTED_MODE' in ifcfg-ib0.  Re-doing ib0."
    /data/xcat/node-setup/setup-ib0.sh
fi
echo "Done."
