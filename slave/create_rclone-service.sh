#!/usr/bin/env bash

SERVER_SHARE_DRIVE=$1

{

cat<<EOF | sudo tee  /etc/systemd/system/rclone.service 

[Unit]
Description=Rclone Google Drive mount
DefaultDependencies=no
After=network.target

[Service]
ExecStart=/usr/bin/rclone -vv mount google-drive:$SERVER_SHARE_DRIVE/ /mnt/GDRIVE/ \\
--poll-interval 0m1s \\
--vfs-cache-mode full \\
--allow-other \\
--allow-non-empty\\
--file-perms 0666 \\
--dir-perms 0777 \\
--vfs-cache-poll-interval 0m1s

Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target

EOF

}