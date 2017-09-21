#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export KUBE_HOME=/usr/local/kubernetes-1.7.5
export MASTER_ADDRESS=192.168.0.107
export KUBE_BIN_DIR=${KUBE_HOME}/bin
export KUBE_CFG_DIR=${KUBE_HOME}/cfg
export KUBE_LOG_DIR=${KUBE_HOME}/logs
export KUBE_SSL_DIR=${KUBE_HOME}/ssl
export KUBE_SERVICE=/usr/lib/systemd/system

echo '============================================================'
echo '===================Config kube-scheduler...================='
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/kube-scheduler file"
cat <<EOF >${KUBE_CFG_DIR}/kube-scheduler
###
# kubernetes scheduler config

# logging to stderr means we get it in the systemd journal,设置为false输出日志到目录
KUBE_LOGTOSTDERR="--logtostderr=false"

# --leader-elect
KUBE_LEADER_ELECT="--leader-elect=true"

#log dir
KUBE_LOG_DIR="--log-dir=${KUBE_LOG_DIR}"

# Add your own!
KUBE_SCHEDULER_ARGS="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"

EOF

echo "Create ${KUBE_SERVICE}/kube-scheduler.service file"
cat <<EOF >${KUBE_SERVICE}/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service
[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-scheduler
ExecStart=${KUBE_BIN_DIR}/kube-scheduler         \\
                        \${KUBE_LOGTOSTDERR}     \\
                        \${KUBE_LOG_LEVEL}       \\
                        \${KUBE_MASTER}          \\
                        \${KUBE_LEADER_ELECT}    \\
                        \${KUBE_LOG_DIR}         \\
                        \${KUBE_SCHEDULER_ARGS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================Start kube-scheduler... ================='
echo '============================================================'

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl restart kube-scheduler

echo "Start kube-scheduler success!"
