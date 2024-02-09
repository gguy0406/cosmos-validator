#!/bin/bash
set -e
$DAEMON_NAME tendermint unsafe-reset-all --keep-addr-book

TRUST_HEIGHT=$(($(curl -s $RPC_ENDPOINT/block | jq -r .result.block.header.height) - "${1:-1000}"))
TRUST_HASH=$(curl -s $RPC_ENDPOINT/block?height=$TRUST_HEIGHT | jq -r .result.block_id.hash)
CONFIG_TOML=$NODE_HOME/config/config.toml

sed -i "s/trust_height = .*/trust_height = \"$TRUST_HEIGHT\"/" $CONFIG_TOML
sed -i "s/trust_hash = .*/trust_hash = \"$TRUST_HASH\"/" $CONFIG_TOML
echo -ne "\e[32m"
sed -n '/^trust_height =/p' $CONFIG_TOML
sed -n '/^trust_hash =/p' $CONFIG_TOML
echo -ne "\e[0m"

$DAEMON_NAME start --x-crisis-skip-assert-invariants
