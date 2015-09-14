#!/bin/bash

provider=$1

cat << EOF > answers.conf
[general]
namespace = default
provider = $provider

[redismaster-app]
image = jasonbrooks/redis
hostport = 6379

[redisslave-app]
image = jasonbrooks/redis
master_hostport = 6379
hostport = 6379
EOF

ret=0

echo "Running projectatomic/redis-centos7-atomicapp"
atomic run projectatomic/redis-centos7-atomicapp
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

if [ $ret -eq 0 ]; then
    if [ "$provider" = "docker" ]; then
        host="0.0.0.0"
        total=0
        docker ps | egrep "redis-master" | egrep -q " Up "
        while [ $? -ne 0 -a $total -lt 120 ]; do
            sleep 2
            total=$((total+2))
            docker ps | egrep "redis-master" | egrep -q " Up "
        done
        sleep 2

        echo "Checking docker containers"
        docker ps

        docker ps | egrep "redis-master" | egrep -q " Up "
        res=$?
        if [ $res -gt $ret ]; then
            ret=$res
        fi

        port=`docker ps | egrep "redis-master" | sed -e "s/.*0.0.0.0://" -e "s/->.*//"`
    elif [ "$provider" = "kubernetes" ]; then
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
    echo "Checking connectivity to master"
    redis-cli -h $host -p $port get key
    res=$?
    if [ $res -gt $ret ]; then
        ret=$res
    fi
fi

echo "Stopping projectatomic/redis-centos7-atomicapp"
atomic stop projectatomic/redis-centos7-atomicapp
res=$?
if [ $res -gt $ret ]; then
    echo "+++++++++++++++++++++++ FAILED ON ATOMIC STOP"
    ret=$res
fi

if [ "$provider" = "docker" ]; then
    docker stop redis-master redis-slave
    docker rm redis-master redis-slave
fi

exit $ret
