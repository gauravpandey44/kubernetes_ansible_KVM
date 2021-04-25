#!/usr/bin/env bash


{

cat<<EOF | sudo tee /etc/systemd/system/docker.service 
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com

[Service]
ExecStart=/usr/local/bin/dockerd -H unix:///var/run/docker.sock \\
  --iptables=false \\
  --ip-masq=false \\
  --host=unix:///var/run/docker.sock \\
  --log-level=error \\
  --storage-driver=overlay
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

}
