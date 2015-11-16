#!/bin/bash

provider=$1

cat << EOF > answers.conf
[general]
provider = $provider

[helloapache-app]
image = centos/httpd
hostport = 80
EOF

ret=0

echo "Running projectatomic/helloapache"
atomicapp run --destination=./ projectatomic/helloapache
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

if [ $ret -eq 0 ]; then
    if [ "$provider" = "kubernetes" ]; then
        total=0
        kubectl get pods | egrep -q "^helloapache\s+1/1s+Running\s+"
        while [ $? -ne 0 -a $total -lt 120 ]; do
           sleep 2
           total=$((total+2))
           kubectl get pods | egrep -q "^helloapache\s+1/1\s+Running\s+"
        done
        
        echo "Checking kubernetes pod"
        kubectl get pods

        kubectl get pods | egrep -q "^helloapache\s+1/1\s+Running\s+"
        res=$?
        if [ $res -gt $ret ]; then
            ret=$res
        fi
    fi

    echo "Running curl"
    curl http://localhost/ | grep 'Apache HTTP Server Test Page powered by CentOS' >& /dev/null
    res=$?
    if [ $res -gt $ret ]; then
        ret=$res
    fi
fi

echo "Stopping projectatomic/helloapache"
atomicapp stop ./
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

exit $ret
