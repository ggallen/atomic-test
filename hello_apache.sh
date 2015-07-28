#!/bin/bash


cat << EOF >> answers.conf
[general]
provider = kubernetes

[helloapache-app]
image = centos/httpd # optional: choose a different image
hostport = 80        # optional: choose a different port to expose
EOF

echo "Running projectatomic/helloapache"
atomic run projectatomic/helloapache

sleep 60
echo "Checking kubernetes pod"
kubectl get pod helloapache

# we might need to wait bit, for the app to be running
echo "Running curl"
curl http://localhost/

echo "Exiting"
exit 0
