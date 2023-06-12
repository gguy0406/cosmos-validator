#!/bin/bash
lastestBlockHeight=$($DAEMON_NAME status | jq -r .SyncInfo.latest_block_height)

while [[ $lastestBlockHeight -lt 1292226 ]]; do
	sleep 6s
	lastestBlockHeight=$($DAEMON_NAME status | jq -r .SyncInfo.latest_block_height)
done

sudo systemctl stop $DAEMON_NAME
cd ~/aura
git fetch
git checkout aura_v0.4.5
make build
rm -r ~/.aura/wasm/wasm/cache
sudo systemctl start aurad

report="$report\n$(date)"
report="$report\n$(systemctl status --no-pager $DAEMON_NAME)"
curlCommand="curl -H 'Content-Type: application/json' -d '{\"username\": \"$(hostname)\", \"content\": $(echo -e "$report" | jq -Rsa)}' https://discord.com/api/webhooks/1106459200525180949/91sf8zCkxBD5R9i4UmGXl2oMNYGZJO_yW1vPKQ39Oo35UvhcJgyCzKF6kMi4_putGEs_"

bash -c "$curlCommand"
