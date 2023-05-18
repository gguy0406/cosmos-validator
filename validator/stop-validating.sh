#!/bin/bash
set -e
sudo systemctl stop $DAEMON_NAME
sudo systemctl disable $DAEMON_NAME
systemctl status --no-pager $DAEMON_NAME
mkdir -p ~/backup
mv $NODE_HOME/config/priv_validator_key.json ~/backup
mv $NODE_HOME/data/priv_validator_state.json ~/backup
