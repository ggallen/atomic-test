#!/bin/bash

echo 'Yum updating the host' 
yum -y -d0 upgrade

echo 'Installing atomic'
yum -y -d 1  install atomic
if [ $? -eq 0 ]; then
  chmod u+x ./hello_apache.sh
  ./hello_apache.sh
  if [ $? -ne 0 ]; then
    echo 'Failed'
    exit 1
  fi
fi
