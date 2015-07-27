#!/bin/bash

service docker start

cat << EOF >> answers.conf
[general]
provider = kubernetes

[helloapache-app]
image = centos/httpd # optional: choose a different image
hostport = 80        # optional: choose a different port to expose
EOF

echo "Running projectatomic/helloapache"
atomic run projectatomic/helloapache

helloapache

exit 0
