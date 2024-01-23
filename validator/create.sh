#!/bin/bash
set -e

$DAEMON_NAME tx staking create-validator \
	--chain-id=$CHAIN_ID \
	--pubkey=$($DAEMON_NAME tendermint show-validator) \
	--amount="1000000$DENOM" \
	# --from=$KEY_NAME \
	--commission-rate="0.05" \
	--commission-max-change-rate="0.01" \
	--commission-max-rate="0.20" \
	# --gas-prices="0.1$DENOM" \
	--gas="auto" \
	--gas-adjustment="1.15" \
	--min-self-delegation="1000000" \
	--moniker=$($DAEMON_NAME status | jq -r .NodeInfo.moniker) \
	# --identity=1C502DEF8B9EBFEE \
	# --details \
	# --website=$website \
	# --security-contact
	-y

$DAEMON_NAME q tendermint-validator-set | grep $($DAEMON_NAME tendermint show-address)
