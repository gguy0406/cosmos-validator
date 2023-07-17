#!/bin/bash
set -e

function getRpcServers {
	echoy "RPC server is not set"
	read -p "Please provide at least 2 valid RPC servers for state sync module (seperate by commas): " RPC_SERVERS

	RPC_SERVERS=$(echo "$RPC_SERVERS" | sed 's/[[:blank:]]//g')
}

# Get node info
echoc "This script load node context base on cosmos chain registry"
echo "You can find more info at https://github.com/cosmos/chain-registry"
read -p "Input chain name: " chainName

chainName=$(echo "$chainName" | sed 's/[[:blank:]]//g')

if [[ -z $chainName ]]; then echo "Error: Invalid input"; exit 1; fi

read -p "Input network type (mainnet/testnet): " networkType

# These value need to checked frequenly
if [[ $networkType = mainnet ]]; then
	REGISTRY_PATH=$chainName/chain.json

	case $chainName in
		aura) RPC_SERVERS=https://snapshot-1.aura.network:443,https://snapshot-2.aura.network:443;;
		stargaze) RPC_SERVERS=https://stargaze-rpc.polkachu.com:443,https://stargaze-rpc.ibs.team:443;;
		stride) RPC_SERVERS=https://stride-rpc.polkachu.com:443,https://stride.rpc.chandrastation.com:443;;
		*) getRpcServers;;
	esac
elif [[ $networkType = testnet ]]; then
	REGISTRY_PATH=testnets/$chainName/chain.json

	case $chainName in
		aura) RPC_SERVERS=https://snapshot-1.euphoria.aura.network:443,https://snapshot-2.euphoria.aura.network:443;;
		*) getRpcServers;;
	esac
else
	echo "Error: Invalid input"
	exit 1
fi

# Install packages
echoc "Installing packages..."
sudo apt install -y jq

# Load chain registry
echoc "Loading chain registry..."
curl -O --fail-with-body https://raw.githubusercontent.com/cosmos/chain-registry/master/$REGISTRY_PATH
PRETTY_NAME=$(cat chain.json | jq -r .pretty_name)
CHAIN_ID=$(cat chain.json | jq -r .chain_id)
DAEMON_NAME=$(cat chain.json | jq -r .daemon_name)
NODE_HOME=$(cat chain.json | jq -r .node_home)
DENOM=$(cat chain.json | jq -r .staking.staking_tokens[0].denom)
GIT_REPO=$(cat chain.json | jq -r .codebase.git_repo)
RECOMMENDED_VERSION=$(cat chain.json | jq -r .codebase.recommended_version)
GENESIS_URL=$(cat chain.json | jq -r .codebase.genesis.genesis_url)

echoc "Finding available seed node..."

for seed in $(cat chain.json | jq -c '.peers.seeds | map({"id":.id,"address":.address}) | .[]'); do
	address=$(echo $seed | jq -r .address)

	if timeout 1s bash -c "true <> /dev/tcp/$(echo $address | sed 's|:|/|')" 2> /dev/null; then
		echog "Adding seed $seed"

		SEEDS+=($(echo $seed | jq -r '.id+"@"+.address'))
	else
		echoy "Seed $address is down"
	fi
done

if [[ ${#SEEDS[@]} -eq 0 ]]; then echor "No seed is set"; fi

NO_SEED=${#SEEDS[@]}
SEEDS=$(echo ${SEEDS[@]} | tr ' ' ',')

echoc "Finding available rpc server..."

for address in $(cat chain.json | jq -r .apis.rpc[].address); do
	if ping -q -c 2 -W 1 $(echo $address | awk -F[/:] '{print $4}') > /dev/null; then
		RPC_ENDPOINT=$(echo $address | sed 's|\/$||')

		echog "Catch $RPC_ENDPOINT"
		break
	fi
done

if [[ -z $RPC_ENDPOINT ]]; then
	echoy "RPC endpoint is not set"
	read -p "Please provide a valid RPC endpoint for state sync module: " RPC_ENDPOINT

	RPC_ENDPOINT=$(echo "$RPC_ENDPOINT" | sed -E 's/[[:blank:]]|\/$//g')
fi

rm chain.json
cat << EOF >> ~/.profile

# Node variables
export CHAIN_NAME=$chainName
export PRETTY_NAME="$PRETTY_NAME"
export CHAIN_ID=$CHAIN_ID
export DAEMON_NAME=$DAEMON_NAME
export NODE_HOME=$NODE_HOME
export DENOM=$DENOM
export GIT_REPO=$GIT_REPO
export RECOMMENDED_VERSION=$RECOMMENDED_VERSION
export GENESIS_URL=$GENESIS_URL
export SEEDS=$SEEDS
export RPC_ENDPOINT=$RPC_ENDPOINT
export RPC_SERVERS=$RPC_SERVERS
EOF
source ~/.profile

# Print set variables
tabs 4
echoc "Make sure everything is set properly"
echog "Chain name:\t\t\t\t$CHAIN_NAME"
echog "Pretty name:\t\t\t$PRETTY_NAME"
echog "Chain id:\t\t\t\t$CHAIN_ID"
echog "Daemon name:\t\t\t$DAEMON_NAME"
echog "Node home:\t\t\t\t$NODE_HOME"
echog "Denom:\t\t\t\t\t$DENOM"
echog "Git repo:\t\t\t\t$GIT_REPO"
echog "Recommended version:\t$RECOMMENDED_VERSION"
echog "Genesis url:\t\t\t$GENESIS_URL"
echog "Seeds ($NO_SEED):\t\t\t\t$SEEDS" | cut -c -$COLUMNS
echog "RPC endpoint:\t\t\t$RPC_ENDPOINT"
echog "RPC servers (manual):\t$RPC_SERVERS"
