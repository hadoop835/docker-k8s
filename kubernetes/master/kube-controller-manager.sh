#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


export MASTER_ADDRESS=192.168.0.107
export KUBE_HOME=/usr/local/kubernetes-1.7.5
export KUBE_BIN_DIR=${KUBE_HOME}/bin
export KUBE_CFG_DIR=${KUBE_HOME}/cfg
export KUBE_LOG_DIR=${KUBE_HOME}/logs
export KUBE_SSL_DIR=${KUBE_HOME}/ssl
export KUBE_SERVICE=/usr/lib/systemd/system
echo '============================================================'
echo '===================Config kube-controller-manager...========'
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/kube-controller-manager file"
cat <<EOF >${KUBE_CFG_DIR}/kube-controller-manager
# logging to stderr means we get it in the systemd journal,设置为false输出日志到目录
KUBE_LOGTOSTDERR="--logtostderr=false"

# --root-ca-file="": If set, this root certificate authority will be included in
# service account's token secret. This must be a valid PEM-encoded CA bundle.
KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE="--root-ca-file=${KUBE_SSL_DIR}/ca.crt"

# --service-account-private-key-file="": Filename containing a PEM-encoded private
# RSA key used to sign service account tokens.
KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE="--service-account-private-key-file=${KUBE_SSL_DIR}/server.key"

#--cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem
KUBE_CLUSTER_SIGNING_CERT_FILE="--cluster-signing-cert-file=${KUBE_SSL_DIR}/ca.crt"

#--cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem
KUBE_CLUSTER_SIGNING_KEY_FILE="--cluster-signing-key-file=${KUBE_SSL_DIR}/ca.key"

# --leader-elect
KUBE_LEADER_ELECT="--leader-elect=true"

#log dir
KUBE_LOG_DIR="--log-dir=${KUBE_LOG_DIR}"

KUBE_CONFIG="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"
EOF


echo "Create ${KUBE_SERVICE}/kube-controller-manager.service file"
cat <<EOF >${KUBE_SERVICE}/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
After=kube-apiserver.service
Requires=kube-apiserver.service
[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-controller-manager
ExecStart=${KUBE_BIN_DIR}/kube-controller-manager \\
                                 \${KUBE_LOGTOSTDERR} \\
                                 \${KUBE_LOG_LEVEL}   \\
                                 \${KUBE_MASTER}      \\
                                 \${KUBE_CLUSTER_SIGNING_CERT_FILE}  \\
                                 \${KUBE_CLUSTER_SIGNING_KEY_FILE}   \\
                                 \${KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE} \\
                                 \${KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE} \\
                                 \${KUBE_CONFIG} \\
                                 \${KUBE_LOG_DIR} \\
                                 \${KUBE_LEADER_ELECT}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo '============================================================'
echo '===================Start kube-controller-manager... ========'
echo '============================================================'

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager

echo "Start kube-controller-manager success!"

