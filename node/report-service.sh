echoc "Get report script"
bash -c "curl --fail-with-body -o ~/minds/report.sh $GH_URL_OPTION/node/report.sh"

echoc "Schedule report"
sudo tee /etc/systemd/system/$DAEMON_NAME-report.service > /dev/null << EOF
[Unit]
Description=$PRETTY_NAME Report

[Service]
Type=oneshot
User=$USER
ExecStart=/bin/bash $HOME/minds/report.sh
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

sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
sudo systemctl enable --now $DAEMON_NAME-report.timer
systemctl status --no-pager -n 0 $DAEMON_NAME-report.service
systemctl status --no-pager -n 0 $DAEMON_NAME-report.timer
