#!/bin/bash
set -e

$DAEMON_NAME tx staking create-validator \
	-y \
	--chain-id="$CHAIN_ID" \
	--from="" \
	--gas="auto" \
	--gas-prices="0.1$DENOM" \
	--gas-adjustment="1.15" \
	--pubkey="$($DAEMON_NAME tendermint show-validator)" \
	--amount="1000000$DENOM" \
	--min-self-delegation="1000000" \
	--commission-rate="0.05" \
	--commission-max-change-rate="0.01" \
	--commission-max-rate="0.20" \
	--moniker="ch0pch0pNFT" \
	--identity="1C502DEF8B9EBFEE" \
	--details="ch0pch0pNFT validator node. Delegate your tokens and start earning staking rewards" \
	--website="https://ch0pch0p.com" \
	--security-contact="lethang.dhsp@gmail.com"

$DAEMON_NAME q tendermint-validator-set | grep $($DAEMON_NAME tendermint show-address)
