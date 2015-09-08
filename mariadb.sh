#!/bin/bash

provider=$1

cat << EOF > answers.conf
[general]
provider = $provider

[mariadb-atomicapp]
db_user = username
db_pass = password
db_name = dbname
EOF

ret=0

echo "Running projectatomic/mariadb-centos7-atomicapp"
atomic run projectatomic/mariadb-centos7-atomicapp
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

if [ $ret -eq 0 ]; then
    host="0.0.0.0"
    if [ "$provider" = "kubernetes" ]; then
        total=0
        kubectl get pods | egrep -q "^mariadb\s+.*\s+Running\s+"
        while [ $? -ne 0 -a $total -lt 120 ]; do
           sleep 2
           total=$((total+2))
           kubectl get pods | egrep -q "^mariadb\s+.*\s+Running\s+"
        done

        echo "Checking kubernetes pod"
        kubectl get pods

        host=`kubectl get service | egrep '^mariadb' | awk '{print $4}'`
    fi

    sleep 3
    echo "Checking databases"
    mysql --host $host --user=username --password=password --execute="show databases;"
    res=$?
    if [ $res -gt $ret ]; then
        ret=$res
    fi
fi

echo "Stopping projectatomic/mariadb-centos7-atomicapp"
atomic stop projectatomic/mariadb-centos7-atomicapp
res=$?
if [ $res -gt $ret ]; then
    ret=$res
fi

exit $ret
