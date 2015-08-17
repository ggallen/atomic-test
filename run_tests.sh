#!/bin/bash

echo 'Yum updating the host' 
yum -y -d0 upgrade

echo 'Installing atomic'
yum -y -d 1  install atomic kubernetes etcd flannel

#Fixing issue #29
cat << EOF > /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/apiserver
User=kube
ExecStart=/usr/bin/kube-apiserver \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBE_ETCD_SERVERS \\
            \$KUBE_API_ADDRESS \\
            \$KUBE_API_PORT \\
            \$KUBELET_PORT \\
            \$KUBE_ALLOW_PRIV \\
            \$KUBE_SERVICE_ADDRESSES \\
            \$KUBE_ADMISSION_CONTROL \\
            \$KUBE_API_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

rtn_code=0
for serv in kube-proxy kubelet kube-scheduler kube-controller-manager kube-apiserver etcd docker; do
  service $serv start 
  rtn=$? ; if [ $rtn -gt $rtn_code ]; then rtn_code=$rtn ; fi
done

sleep 5

if [ $rtn_code -eq 0 ]; then
  chmod u+x ./hello_apache.sh
  ./hello_apache.sh
  rtn_code=$?
fi

for serv in docker etcd kube-apiserver kube-controller-manager kube-scheduler kubelet kube-proxy; do
  service $serv stop 
done

if [ $rtn_code -ne 0 ]; then
  echo 'Failed'
fi
exit $rtn_code
