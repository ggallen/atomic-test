#!/bin/bash

service docker start

echo "Running projectatomic/helloapache"
atomic run projectatomic/helloapache
