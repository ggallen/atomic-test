#!/bin/bash

source functions.sh $*

echo 'Yum updating the host' 
yum -y -d0 upgrade

echo 'Installing atomic'
yum -y -d 1  install atomic kubernetes etcd flannel

echo 'Configuring kubernetes'
key_dir="/etc/pki/kube-apiserver"
key_file="$key_dir/serviceaccount.key"
mkdir -p $key_dir
/bin/openssl genrsa -out $key_file 2048
sed -i -e "s%KUBE_API_ARGS=\".*\"%KUBE_API_ARGS=\"--service_account_key_file=$key_file\"%" /etc/kubernetes/apiserver
sed -i -e "s%KUBE_CONTROLLER_MANAGER_ARGS=\".*\"%KUBE_API_ARGS=\"--service_account_private_key_file=$key_file\"%" /etc/kubernetes/controller-manager

startup
rtn_code=$?

if [ $rtn_code -eq 0 ]; then
  chmod u+x ./hello_apache.sh
  ./hello_apache.sh -p $provider
  rtn_code=$?
fi

shutdown

if [ $rtn_code -ne 0 ]; then
  echo 'Failed'
fi
exit $rtn_code
