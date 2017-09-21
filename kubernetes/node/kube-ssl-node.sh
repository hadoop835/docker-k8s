#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

export HUBE_HOME=/usr/local/kubernetes-1.7.5
export KUBE_SSL_DIR=${HUBE_HOME}/ssl

echo '============================================================'
echo '===================Create ssl for kube node...=============='
echo '============================================================'

#创建证书存放目录
# rm -rf ${KUBE_SSL_DIR}
# mkdir  ${KUBE_SSL_DIR}

###############生成node端证书################
openssl genrsa -out ${KUBE_SSL_DIR}/kube_client.key 2048

openssl req -new -key ${KUBE_SSL_DIR}/kube_client.key -subj "/CN=slave1" -out ${KUBE_SSL_DIR}/kube_client.csr
#cp -rf /usr/local/kubernetes-1.7.5/ssl/ca.* ${KUBE_SSL_DIR}
openssl x509 -req -in ${KUBE_SSL_DIR}/kube_client.csr -CA ${KUBE_SSL_DIR}/ca.crt -CAkey ${KUBE_SSL_DIR}/ca.key -CAcreateserial -out ${KUBE_SSL_DIR}/kube_client.crt -days 10000
