#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail


export KUBE_MASTER_IP=192.168.0.107
export KUBE_SLAVE_IP_1=192.168.0.108
export KUBE_SLAVE_IP_2=192.168.0.109
#KUBE_MASTER_DNS=${2:-}
export HUBE_HOME=/usr/local/kubernetes-1.7.5
export KUBE_CLUSTER_IP=10.0.0.1
export KUBE_CFG_DIR=${HUBE_HOME}/cfg
export KUBE_SSL_DIR=${HUBE_HOME}/ssl


echo '============================================================'
echo '===================Create ssl for kube master node...======='
echo '============================================================'

#创建证书存放目录
rm -rf ${KUBE_SSL_DIR}
mkdir ${KUBE_SSL_DIR}

###############生成根证书################
#创建CA私钥
openssl genrsa -out ${KUBE_SSL_DIR}/ca.key 2048
#自签CA
openssl req -x509 -new -nodes -key ${KUBE_SSL_DIR}/ca.key -subj "/CN=kubernetes/O=k8s/OU=System" -days 10000 -out ${KUBE_SSL_DIR}/ca.crt
###############生成 API Server 服务端证书和私钥###############

cat <<EOF >${KUBE_SSL_DIR}/master_ssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
IP.1 = 127.0.0.1
IP.2 = ${KUBE_CLUSTER_IP}
IP.3 = ${KUBE_MASTER_IP}
IP.4 = ${KUBE_SLAVE_IP_1}
IP.5 = ${KUBE_SLAVE_IP_2}

EOF

#生成apiserver私钥
echo "Create kubernetes api server ssl key..."
openssl genrsa -out ${KUBE_SSL_DIR}/server.key 2048

#生成签署请求
openssl req -new -key ${KUBE_SSL_DIR}/server.key -subj "/CN=kubernetes/O=k8s/OU=System" -config ${KUBE_SSL_DIR}/master_ssl.cnf -out ${KUBE_SSL_DIR}/server.csr

#使用自建CA签署
openssl x509 -req -in ${KUBE_SSL_DIR}/server.csr -CA ${KUBE_SSL_DIR}/ca.crt -CAkey ${KUBE_SSL_DIR}/ca.key -CAcreateserial -days 10000 -extensions v3_req -extfile ${KUBE_SSL_DIR}/master_ssl.cnf -out ${KUBE_SSL_DIR}/server.crt

#生成 Controller Manager 与 Scheduler 进程共用的证书和私钥
echo "Create kubernetes controller manager and scheduler server ssl key..."
openssl genrsa -out ${KUBE_SSL_DIR}/cs_client.key 2048

#生成签署请求
openssl req -new -key  ${KUBE_SSL_DIR}/cs_client.key -subj "/CN=admin/O=system:masters/OU=System" -out ${KUBE_SSL_DIR}/cs_client.csr

#使用自建CA签署
openssl x509 -req -in ${KUBE_SSL_DIR}/cs_client.csr -CA ${KUBE_SSL_DIR}/ca.crt -CAkey ${KUBE_SSL_DIR}/ca.key -CAcreateserial -out ${KUBE_SSL_DIR}/cs_client.crt -days 10000
