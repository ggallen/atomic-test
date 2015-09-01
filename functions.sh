#!/bin/bash

docker_services="etcd docker"
kubernetes_services="kube-proxy kubelet kube-scheduler kube-controller-manager kube-apiserver $docker_services"

provider="docker"
services="$docker_services"

function parse_opts {
    local OPTIND opt p
    while getopts "p:" opt; do
        case $opt in
        p)
            provider="$OPTARG"
            ;;
        esac
   done

   shift $((OPTIND - 1))
}

function startup {
    if [ "$provider" = "docker" ]; then
        services="$docker_services"
    elif [ "$provider" = "kubernetes" ]; then
        services="$kubernetes_services"
        fix_kubernetes_issue_29
    else
        echo "Unknown provider '$provider'"
        exit 1 
    fi
    shutdown
    start_services
}

function shutdown {
    rm -rf .workdir Dockerfile Nulecule answers.conf artifacts
    stop_services
}

function start_services {
    rtn_code=0
    for s in $services; do
        service $s start
        if [ $? -gt $rtn_code ]; then
            rtn_code=$?
        fi
    done

    sleep 5
    return $rtn_code
}

function stop_services {
    for s in $services; do
        service $s stop
    done
    return 0
}

function fix_kubernetes_issue_29 {
    # Fixing issue #29
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
}

parse_opts $*
