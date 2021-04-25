#!/usr/bin/env bash

ETCD_NAME=$1
INTERNAL_IP=$2

MASTER_ALL_HOSTS_ARR=(`cat /tmp/master_hostnames.out | sed 's/,/ /g'`)    #MASTER HOST NAMES IN ARRAY

MASTER_ALL_IPS_ARR=(`cat /tmp/master_ips.out | sed 's/,/ /g'`)   #MASTER IPs IN ARRAY

NO_OF_MASTER=${#MASTER_ALL_HOSTS_ARR[@]}

i=0

INITIAL_CLUSTER_DETAILS="$ETCD_NAME=https://$INTERNAL_IP:2380"

while [ $i -lt $NO_OF_MASTER ]
do
    
    
    ip=`echo "https://${MASTER_ALL_IPS_ARR[$i]}:2380"`
    host=${MASTER_ALL_HOSTS_ARR[$i]}
    if [ "$host" != "$ETCD_NAME" ]
    then
        INITIAL_CLUSTER_DETAILS+=",$host=$ip"
    fi
    i=$(( $i + 1 ))

done
#echo $INITIAL_CLUSTER_DETAILS

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://$INTERNAL_IP:2380 \\
  --listen-peer-urls https://$INTERNAL_IP:2380 \\
  --listen-client-urls https://$INTERNAL_IP:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://$INTERNAL_IP:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster $INITIAL_CLUSTER_DETAILS \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
