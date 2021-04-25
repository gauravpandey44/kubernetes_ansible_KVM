#!/usr/bin/env bash

# Script to Generate all the keys for a slave
#This script is run on any remote access system 
#There are different keys for different slaves and hence this script is run for different slaves



SLAVE_ALL_HOSTS="$1"     #SLAVE HOST NAME WITH , SEPPERATED
SLAVE_ALL_IPS="$2"
cluster_name="$3"
KUBERNETES_PUBLIC_ADDRESS="$4"      #load balancer address

SLAVE_ALL_HOSTS_ARR=(`echo "$SLAVE_ALL_HOSTS" | sed 's/,/ /g'`)    #SLAVE HOST NAMES IN ARRAY

SLAVE_ALL_IPS_ARR=(`echo "$SLAVE_ALL_IPS" | sed 's/,/ /g'`)   #SLAVE IPs IN ARRAY

NO_OF_SLAVES=${#SLAVE_ALL_HOSTS_ARR[@]}

echo $SLAVE_ALL_HOSTS >/tmp/t2.test
echo $SLAVE_ALL_IPS >>/tmp/t2.test
echo $cluster_name >>/tmp/t2.test
echo $KUBERNETES_PUBLIC_ADDRESS >>/tmp/t2.test
#----------------------------------------------------------------------------------------------------------


#The Kubelet Client Certificates
#This will be different for different slave
i=0
while [ $i -lt $NO_OF_SLAVES ]
do
         
        WORKER_HOST=${SLAVE_ALL_HOSTS_ARR[$i]}
        WORKER_IP=${SLAVE_ALL_IPS_ARR[$i]}
        cat > ${WORKER_HOST}-csr.json <<EOF
        {
          "CN": "system:node:${WORKER_HOST}",
          "key": {
            "algo": "rsa",
            "size": 2048
          },
          "names": [
            {
              "C": "US",
              "L": "Portland",
              "O": "system:nodes",
              "OU": "$cluster_name",
              "ST": "Oregon"
            }
          ]
        }
EOF

        cfssl gencert \
          -ca=ca.pem \
          -ca-key=ca-key.pem \
          -config=ca-config.json \
          -hostname=${WORKER_IP},${WORKER_HOST} \
          -profile=kubernetes \
          ${WORKER_HOST}-csr.json | cfssljson -bare ${WORKER_HOST}
         
         i=$(( $i + 1 ))
        
done

#----------------------------------------------------------------------------------------------------------

#The Kube Proxy Client Certificate
#This will be same for different slave



cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "system:node-proxier",
      "OU": "$cluster_name",
      "ST": "Oregon"
    }
  ]
}
EOF

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kube-proxy-csr.json | cfssljson -bare kube-proxy



#----------------------------------------------------------------------------------------------------------
#The kubelet Kubernetes Configuration File:
#This will be different for different slave



i=0
while [ $i -lt $NO_OF_SLAVES ]  
do
         
        WORKER_HOST=${SLAVE_ALL_HOSTS_ARR[$i]}
        WORKER_IP=${SLAVE_ALL_IPS_ARR[$i]}

      kubectl config set-cluster $cluster_name \
        --certificate-authority=ca.pem \
        --embed-certs=true \
        --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
        --kubeconfig=${WORKER_HOST}.kubeconfig

      kubectl config set-credentials system:node:${WORKER_HOST} \
        --client-certificate=${WORKER_HOST}.pem \
        --client-key=${WORKER_HOST}-key.pem \
        --embed-certs=true \
        --kubeconfig=${WORKER_HOST}.kubeconfig

      kubectl config set-context default \
        --cluster=$cluster_name \
        --user=system:node:${WORKER_HOST} \
        --kubeconfig=${WORKER_HOST}.kubeconfig

      kubectl config use-context default --kubeconfig=${WORKER_HOST}.kubeconfig
      
      i=$(( $i + 1 ))
done

#----------------------------------------------------------------------------------------------------------


#The kube-proxy Kubernetes Configuration File
#This will be same for different slave



  kubectl config set-cluster $cluster_name \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=$cluster_name \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
