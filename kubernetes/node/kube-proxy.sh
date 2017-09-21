#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


export NODE_ADDRESS=192.168.0.107
export MASTER_ADDRESS=192.168.0.107
export KUBE_HOME=/usr/local/kubernetes-1.7.5
export KUBE_BIN_DIR=${KUBE_HOME}/bin
export KUBE_CFG_DIR=${KUBE_HOME}/cfg

echo '============================================================'
echo '===================Config kube-proxy... ===================='
echo '============================================================'

echo "Create ${KUBE_CFG_DIR}/kube-proxy file"
cat <<EOF >${KUBE_CFG_DIR}/kube-proxy
# --hostname-override="": If non-empty, will use this string as identification instead of the actual hostname.
NODE_HOSTNAME="--hostname-override=${NODE_ADDRESS}"

# Add your own!
KUBE_PROXY_ARGS="--kubeconfig=${KUBE_CFG_DIR}/kubeconfig.yaml"
EOF

echo "Create /usr/lib/systemd/system/kube-proxy.service file"
cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-${KUBE_CFG_DIR}/config
EnvironmentFile=-${KUBE_CFG_DIR}/kube-proxy
ExecStart=${KUBE_BIN_DIR}/kube-proxy     \
                    \${KUBE_LOGTOSTDERR} \
                    \${KUBE_LOG_LEVEL}   \
                    \${NODE_HOSTNAME}    \
                    \${KUBE_MASTER}      \
                    \${KUBE_PROXY_ARGS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "============================================================"
echo "===================Start kube-proxy... ====================="
echo "============================================================"

systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy

echo "Start kube proxy success!"
