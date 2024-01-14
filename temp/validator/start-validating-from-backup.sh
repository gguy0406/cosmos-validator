#!/bin/bash
set -e

lastestBlockHeight=$($DAEMON_NAME status | jq -r .SyncInfo.latest_block_height)
VALIDATOR_HEIGHT=$(cat ~/backup/priv_validator_state.json | jq -r .height)

while [[ $lastestBlockHeight -le $VALIDATOR_HEIGHT ]]; do
	echoy "Lastest block height is not exceed validator height yet ($lastestBlockHeight/$VALIDATOR_HEIGHT)"
	sleep 6s
	lastestBlockHeight=$($DAEMON_NAME status | jq -r .SyncInfo.latest_block_height)
done

sudo systemctl stop $DAEMON_NAME
cp -f ~/backup/priv_validator_key.json $NODE_HOME/config
sudo systemctl restart $DAEMON_NAME
