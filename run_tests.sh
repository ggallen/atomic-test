#!/bin/bash

source functions.sh $*

echo 'Yum updating the host' 
yum -y -d0 upgrade

echo 'Installing atomic'
yum -y -d 1  install atomic kubernetes etcd flannel

for provider in $providers; do
    configure $provider

    startup $provider
    rtn_code=$?

    if [ $rtn_code -eq 0 ]; then
        chmod u+x ./hello_apache.sh
        ./hello_apache.sh $provider
        rtn_code=$?
    fi

    shutdown $provider

    if [ $rtn_code -ne 0 ]; then
        echo 'Failed'
    fi
done
exit $rtn_code
