#!/bin/bash

source functions.sh

cat << EOF > answers.conf
[general]
provider = $provider

[helloapache-app]
image = centos/httpd
hostport = 80
EOF

ret=0

echo "Running projectatomic/helloapache"
atomic run projectatomic/helloapache
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

if [ $ret -eq 0 ]; then
    if [ "$provider" = "kubernetes" ]; then
        total=0
        kubectl get pods | egrep -q "^\s+helloapache\s+centos/httpd\s+Running\s+[0-9]"
        while [ $? -ne 0 -a $total -lt 120 ]; do
           sleep 5
           total=$((total+5))
           kubectl get pods | egrep -q "^\s+helloapache\s+centos/httpd\s+Running\s+[0-9]"
        done
        
        echo "Checking kubernetes pod"
        kubectl get pods
    fi

    # we might need to wait bit, for the app to be running
    echo "Running curl"
    curl http://localhost/ | grep 'Apache HTTP Server Test Page powered by CentOS' >& /dev/null
    res=$?
    if [ $res -gt $ret ]; then
        ret=$res
    fi
fi

echo "Stopping projectatomic/helloapache"
atomic stop projectatomic/helloapache
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

exit $ret
