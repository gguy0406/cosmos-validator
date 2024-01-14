#!/bin/bash
set -e

if [[ -z $1 ]]; then echo "Need to specify discord webhook token"; exit 1; fi

cat << EOF >> ~/.profile

# Report variables
export SIGNED_BLOCKS_WINDOW=$RPC_SERVERS
export VALIDATOR_ADDRESS=$RPC_SERVERS
export DISCORD_WEBHOOK_URL=$1
EOF

echoc "Get report script"
bash -c "curl --fail-with-body -o ~/minds/status-report.sh $GH_URL_OPTION/node/status-report.sh"
bash -c "curl --fail-with-body -o ~/minds/miss-block-report.js $GH_URL_OPTION/node/miss-block-report.js"

echoc "Schedule report"
sudo tee /etc/systemd/system/$DAEMON_NAME-status-report.service > /dev/null << EOF
[Unit]
Description=$PRETTY_NAME Report

[Service]
Type=oneshot
User=$USER
ExecStart=/bin/bash $HOME/minds/status-report.sh
Group=systemd-journal
EOF

sudo tee /etc/systemd/system/$DAEMON_NAME-report.timer > /dev/null << EOF
[Unit]
Description=Report $DAEMON_NAME hourly

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo tee /etc/systemd/system/$DAEMON_NAME-miss-block-report.service > /dev/null << EOF
[Unit]
Description=Miss Block Report

[Service]
ExecStart=/usr/bin/node $HOME/minds/miss-block-report.js
Restart=on-failure
RestartSec=3
User=nobody

[Install]
WantedBy=multi-user.target
EOF

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash
sudo apt install -y nodejs
npm i -g ws
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
sudo systemctl enable --now $DAEMON_NAME-report.timer
systemctl status --no-pager -n 0 $DAEMON_NAME-report.service
systemctl status --no-pager -n 0 $DAEMON_NAME-report.timer
