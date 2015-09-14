#!/bin/bash

provider=$1

cat << EOF > answers.conf
[general]
namespace = default
provider = $provider

[redismaster-app]
hostport = 16379

[redisslave-app]
master_hostport = 16379
EOF

ret=0

echo "Running projectatomic/redis-centos7-atomicapp"
atomic run projectatomic/redis-centos7-atomicapp
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

if [ $ret -eq 0 ]; then
    if [ "$provider" = "kubernetes" ]; then
        total=0
        kubectl get pods | egrep -q "^redis-master-.*\s+Running\s+"
        while [ $? -ne 0 -a $total -lt 120 ]; do
            sleep 2
            total=$((total+2))
            kubectl get pods | egrep -q "^redis-master-.*\s+Running\s+"
        done

        echo "Checking kubernetes pod"
        kubectl get pods

        kubectl get pods | egrep -q "^redis-master-.*\s+Running\s+"
        res=$?
        if [ $res -gt $ret ]; then
            ret=$res
        fi
    fi

    sleep 3
    echo "Checking databases"
    mysql --host 0.0.0.0 --user=username --password=password --execute="show databases;"
    res=$?
    if [ $res -gt $ret ]; then
        ret=$res
    fi
fi

echo "Stopping projectatomic/redis-centos7-atomicapp"
atomic stop projectatomic/redis-centos7-atomicapp
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

exit $ret
