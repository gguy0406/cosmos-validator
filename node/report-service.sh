#!/bin/bash
set -e

DISCORD_WEBHOOK_URL=$1
VALIDATOR_ADDRESS=$2

if [[ -z $DISCORD_WEBHOOK_URL ]]; then echo "Missing discord webhook url"; exit 1; fi
if [[ -z $VALIDATOR_ADDRESS ]]; then echo "Missing validator address"; exit 1; fi

cat << EOF >> ~/.profile

# Report variables
export SIGNED_BLOCKS_WINDOW=$(cat $NODE_HOME/config/genesis.json | jq -r ".app_state.slashing.params.signed_blocks_window")
export VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS
export DISCORD_WEBHOOK_URL=$DISCORD_WEBHOOK_URL
EOF

echoc "Get report script"
bash -c "curl --fail-with-body -o ~/minds/status-report.sh $GH_URL_OPTION/node/status-report.sh"
mkdir ~/minds/miss-block-report
bash -c "curl --fail-with-body -o ~/minds/miss-block-report/report.js $GH_URL_OPTION/node/miss-block-report.js"

echoc "Schedule report"
sudo tee /etc/systemd/system/$DAEMON_NAME-status-report.service > /dev/null << EOF
[Unit]
Description=$PRETTY_NAME Status Report

[Service]
Type=oneshot
User=$USER
ExecStart=/bin/bash $HOME/minds/status-report.sh
Group=systemd-journal
EOF

sudo tee /etc/systemd/system/$DAEMON_NAME-status-report.timer > /dev/null << EOF
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
ExecStart=/usr/bin/node $HOME/minds/miss-block-report/report.js $DISCORD_WEBHOOK_URL $(hostname)
Restart=on-failure
RestartSec=3
User=$USER

[Install]
WantedBy=multi-user.target
EOF

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash
sudo apt install -y nodejs
cd ~/minds/miss-block-report
npm i ws
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
sudo systemctl enable --now $DAEMON_NAME-status-report.timer $DAEMON_NAME-miss-block-report.service
systemctl status --no-pager -n 0 $DAEMON_NAME-status-report.timer $DAEMON_NAME-miss-block-report.service
