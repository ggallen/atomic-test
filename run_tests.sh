#!/bin/bash

source functions.sh $*

install_packages

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
