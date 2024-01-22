#!/bin/bash
set -e

# Set journalctl limit
echoc "Set journalctl limit"
sudo journalctl --vacuum-size=1G --vacuum-time=7days

# Create service file and start the daemon
echoc "Create service file and start the daemon"
sudo tee /etc/systemd/system/$DAEMON_NAME.service > /dev/null << EOF
[Unit]
Description=$PRETTY_NAME Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which $DAEMON_NAME) start
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
sudo systemctl enable --now $DAEMON_NAME
monitorService
