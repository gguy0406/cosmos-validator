#!/bin/bash
set -e

# Install packages
echoc "Installing packages..."
sudo apt install -y build-essential git

# Get chain repository
echoc "Getting chain repository..."
git clone -b $RECOMMENDED_VERSION $GIT_REPO ~/$CHAIN_NAME
cd ~/$CHAIN_NAME

# Install Go
echoc "Installing Go..."
GO_SHORT_VERSION=$(grep -m 1 go go.mod | cut -d' ' -f2)
GO_VERSION_REGEX="^go$GO_SHORT_VERSION(\.[0-9]+|)$"
GO_VERSION=$(curl -s "https://go.dev/dl/?mode=json&include=all" | jq -r ".[].version" | grep -E $GO_VERSION_REGEX | sort -V | tail -n 1)
ARCH=$(uname -m)

case $ARCH in
	x86_64) ARCH=amd64;;
	aarch64 | armv8) ARCH=arm64;;
	armv6l | armv7l) ARCH=armv6l;;
	i386) ARCH=386;;
	*) unset ARCH;;
esac

if [[ -z $ARCH ]]; then echo "Error: Your operating system is not supported by the script"; exit 1; fi

wget -O go.tar.gz https://go.dev/dl/$GO_VERSION.linux-$ARCH.tar.gz
sudo tar -xzf go.tar.gz -C /usr/local
rm go.tar.gz
echo -e "\n# Go\nexport PATH=\$PATH:/usr/local/go/bin\nexport PATH=\$PATH:/\$HOME/go/bin" >> ~/.profile
source ~/.profile
go version

# Install daemon binary
echoc "Installing daemon binary..."
make install
$DAEMON_NAME version
cd ~

# Inititialize chain
echoc "Initialize chain"
NODE_MONIKER="$CHAIN_NAME-$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 8)"

$DAEMON_NAME config chain-id $CHAIN_ID
$DAEMON_NAME init --chain-id $CHAIN_ID $NODE_MONIKER

# Config chain seeds, genenis, etc..
echoc "Config chain genenis, seeds, state sync, etc.."
fileExtension="${GENESIS_URL##*.}"

case $chainName in
	.gz) wget -O genesis.tar.gz $GENESIS_URL; sudo tar -xzf genesis.tar.gz -C $NODE_HOME/config; rm genesis.tar.gz;;
	.json) wget -O $NODE_HOME/config/genesis.json $GENESIS_URL;;
	*) echo "Error getting file extension"; exit 1;;
esac

APP_TOML=$NODE_HOME/config/app.toml
CONFIG_TOML=$NODE_HOME/config/config.toml

sed -i "s/min-retain-blocks = .*/min-retain-blocks = 250000/" $APP_TOML
sed -i "s/pruning = .*/pruning = \"custom\"/" $APP_TOML
sed -i "s/pruning-keep-recent = .*/pruning-keep-recent = \"100\"/" $APP_TOML
sed -i "s/pruning-interval = .*/pruning-interval = \"10\"/" $APP_TOML
sed -i "s/snapshot-interval = .*/snapshot-interval = 0/" $APP_TOML
sed -i "s/seeds = .*/seeds = \"$SEEDS\"/" $CONFIG_TOML
sed -i "s/max_num_inbound_peers = .*/max_num_inbound_peers = 120/" $CONFIG_TOML
sed -i "s/max_num_outbound_peers = .*/max_num_outbound_peers = 60/" $CONFIG_TOML
sed -i "s/indexer = .*/indexer = \"null\"/" $CONFIG_TOML
sed -i "s/enable = false/enable = true/" $CONFIG_TOML

echo -ne "\e[32m"
sed -n '/^minimum-gas-prices =/p' $APP_TOML
sed -n '/^min-retain-blocks =/p' $APP_TOML
sed -n '/^pruning =/p' $APP_TOML
sed -n '/^pruning-keep-recent =/p' $APP_TOML
sed -n '/^pruning-interval =/p' $APP_TOML
sed -n '/^snapshot-interval =/p' $APP_TOML
sed -n '/^seeds =/p' $CONFIG_TOML
sed -n '/^max_num_inbound_peers =/p' $CONFIG_TOML
sed -n '/^max_num_outbound_peers =/p' $CONFIG_TOML
sed -n '/^indexer =/p' $CONFIG_TOML
sed -n '/^enable =/p' $CONFIG_TOML
sed -n '/^rpc_servers =/p' $CONFIG_TOML
echo -ne "\e[0m"

executeScript node/chain-specific-setting/$CHAIN_NAME

TRUST_HEIGHT=$(($(curl -s $RPC_ENDPOINT/block | jq -r .result.block.header.height) - 1000))
TRUST_HASH=$(curl -s $RPC_ENDPOINT/block?height=$TRUST_HEIGHT | jq -r .result.block_id.hash)

sed -i "s/trust_height = .*/trust_height = \"$TRUST_HEIGHT\"/" $CONFIG_TOML
sed -i "s/trust_hash = .*/trust_hash = \"$TRUST_HASH\"/" $CONFIG_TOML
echo -ne "\e[32m"
sed -n '/^trust_height =/p' $CONFIG_TOML
sed -n '/^trust_hash =/p' $CONFIG_TOML
echo -ne "\e[0m"
$DAEMON_NAME start --x-crisis-skip-assert-invariants
