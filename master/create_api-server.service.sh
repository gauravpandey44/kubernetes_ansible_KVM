#!/usr/bin/env bash

ETCD_NAME=$1
INTERNAL_IP=$2

MASTER_ALL_HOSTS_ARR=(`cat /tmp/master_hostnames.out | sed 's/,/ /g'`)    #MASTER HOST NAMES IN ARRAY

MASTER_ALL_IPS_ARR=(`cat /tmp/master_ips.out | sed 's/,/ /g'`)   #MASTER IPs IN ARRAY

NO_OF_MASTER=${#MASTER_ALL_HOSTS_ARR[@]}

i=0

ETCD_SERVERS="https://$INTERNAL_IP:2379"

while [ $i -lt $NO_OF_MASTER ]
do
    
    
    ip=`echo "https://${MASTER_ALL_IPS_ARR[$i]}:2379"`
    host=${MASTER_ALL_HOSTS_ARR[$i]}
    if [ "$host" != "$ETCD_NAME" ]
    then
        ETCD_SERVERS+=",$ip"
    fi
    i=$(( $i + 1 ))

done
echo $ETCD_SERVERS




cat <<EOF | sudo tee /etc/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --advertise-address=$INTERNAL_IP \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=$ETCD_SERVERS \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/service-account.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2 \\
  --kubelet-preferred-address-types=InternalIP,InternalDNS,Hostname,ExternalIP,ExternalDNS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
