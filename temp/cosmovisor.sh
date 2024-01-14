#!/bin/bash
set -e
cd ~
go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@latest
cosmovisor version
cp cosmovisor/cosmovisor ~/go/bin/cosmovisor
cat << EOF >> ~/.profile

# Cosmovisor
export DAEMON_HOME=$NODE_HOME
export DAEMON_RESTART_AFTER_UPGRADE=true
EOF
source ~/.profile

