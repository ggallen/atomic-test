#!/bin/bash

cat << EOF > answers.conf
[general]
provider = kubernetes

[helloapache-app]
image = centos/httpd # optional: choose a different image
hostport = 80        # optional: choose a different port to expose
EOF

echo "Running projectatomic/helloapache"
atomic run projectatomic/helloapache

kubectl get pods | egrep -q "^\s+helloapache\s+centos/httpd\s+Running\s+[0-9]"
while [ $? -ne 0 ]; do
   sleep 5
   kubectl get pods | egrep -q "^\s+helloapache\s+centos/httpd\s+Running\s+[0-9]"
done

#echo "Checking kubernetes pod"
#kubectl get pods

# we might need to wait bit, for the app to be running
echo "Running curl"
curl http://localhost/ | grep -q 'Apache HTTP Server Test Page powered by CentOS'
ret=$?

echo "Stopping projectatomic/helloapache"
atomic stop projectatomic/helloapache

echo "Exiting"
exit $ret
