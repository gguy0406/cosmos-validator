#!/bin/bash
set -e

GO_VERSION=1.20.5
APP_TOML=$NODE_HOME/config/app.toml
CONFIG_TOML=$NODE_HOME/config/config.toml

function getTrustHeight {
	TRUST_HEIGHT=$(($(curl -s $RPC_ENDPOINT/block | jq -r .result.block.header.height) - $1))
	TRUST_HASH=$(curl -s $RPC_ENDPOINT/block?height=$TRUST_HEIGHT | jq -r .result.block_id.hash)

	sed -i "s/trust_height = .*/trust_height = \"$TRUST_HEIGHT\"/" $CONFIG_TOML
	sed -i "s/trust_hash = .*/trust_hash = \"$TRUST_HASH\"/" $CONFIG_TOML
	echo -ne "\e[32m"
	sed -n '/^trust_height =/p' $CONFIG_TOML
	sed -n '/^trust_hash =/p' $CONFIG_TOML
	echo -ne "\e[0m"
}

function turnOffStateSync {
	sleep 30m
	sed -i "s/enable = true/enable = false/" $CONFIG_TOML
	sed -i "s/log_level = .*/log_level = "warn"/" $CONFIG_TOML
}

function resetStateSync {
	sudo systemctl stop $DAEMON_NAME
	$DAEMON_NAME tendermint unsafe-reset-all --keep-addr-book
	getTrustHeight $1
	sed -i "s/enable = false/enable = true/" $CONFIG_TOML
	echo -ne "\e[32m"
	sed -n '/^enable =/p' $CONFIG_TOML
	echo -ne "\e[0m"
	sudo systemctl restart systemd-journald
	sudo systemctl restart $DAEMON_NAME
	turnOffStateSync &
	monitorService
}

# Read moniker
read -p "Name your moniker: " nodeMoniker

nodeMoniker=$(echo "$nodeMoniker" | sed 's/[[:blank:]]/-/g')

if [[ -z $nodeMoniker ]]; then
	nodeMoniker="$CHAIN_NAME-$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 8)"

	echog "Generated random moniker: $nodeMoniker"
fi

# Install packages
echoc "Installing packages..."
sudo apt install -y build-essential git

# Install Go
echoc "Installing Go..."

ARCH=$(uname -m)

case $ARCH in
	x86_64) ARCH=amd64;;
	aarch64 | armv8) ARCH=arm64;;
	armv6l | armv7l) ARCH=armv6l;;
	i386) ARCH=386;;
	*) unset ARCH;;
esac

if [[ -z $ARCH ]]; then echo "Error: Your operating system is not supported by the script"; exit 1; fi

wget -O go.tar.gz https://go.dev/dl/go$GO_VERSION.linux-$ARCH.tar.gz
sudo tar -xzf go.tar.gz -C /usr/local
rm go.tar.gz
echo -e "\n# Go\nexport PATH=\$PATH:/usr/local/go/bin\nexport PATH=\$PATH:/\$HOME/go/bin" >> ~/.profile
source ~/.profile
go version

# Install daemon
echoc "Installing daemon..."
git clone -b $RECOMMENDED_VERSION $GIT_REPO ~/$CHAIN_NAME
cd ~/$CHAIN_NAME
make
$DAEMON_NAME version
cd ~

# Inititialize chain
echoc "Initialize chain"
$DAEMON_NAME config chain-id $CHAIN_ID
$DAEMON_NAME init --chain-id $CHAIN_ID $nodeMoniker

# Config chain seeds, genenis, etc..
echoc "Config chain genenis, seeds, state sync, etc.."
wget -O $NODE_HOME/config/genesis.json $GENESIS_URL
sed -i "s/minimum-gas-prices = .*/minimum-gas-prices = \"0.0025$DENOM\"/" $APP_TOML
sed -i "s/min-retain-blocks = .*/min-retain-blocks = 250000/" $APP_TOML
# sed -i "s/pruning = .*/pruning = \"custom\"/" $APP_TOML
# sed -i "s/pruning-keep-recent = .*/pruning-keep-recent = \"100\"/" $APP_TOML
# sed -i "s/pruning-interval = .*/pruning-interval = \"10\"/" $APP_TOML
# sed -i "s/snapshot-interval = .*/snapshot-interval = 0/" $APP_TOML
sed -i "s/seeds = .*/seeds = \"$SEEDS\"/" $CONFIG_TOML
sed -i "s/max_num_inbound_peers = .*/max_num_inbound_peers = 120/" $CONFIG_TOML
sed -i "s/max_num_outbound_peers = .*/max_num_outbound_peers = 60/" $CONFIG_TOML
sed -i "s/indexer = .*/indexer = \"null\"/" $CONFIG_TOML
sed -i "s/enable = false/enable = true/" $CONFIG_TOML
sed -i "s|rpc_servers = .*|rpc_servers = \"$RPC_SERVERS\"|" $CONFIG_TOML

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
getTrustHeight 1000

# Create service file and start the daemon
echoc "Create service file and start the daemon"
sudo tee /etc/systemd/system/$DAEMON_NAME.service > /dev/null << EOF
[Unit]
Description=$PRETTY_NAME Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which $DAEMON_NAME) start --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
sudo mv /etc/systemd/system/$DAEMON_NAME.service /lib/systemd/system
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald
sudo systemctl enable --now $DAEMON_NAME
turnOffStateSync &
monitorService
