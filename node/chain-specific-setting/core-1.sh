#!/bin/bash
set -e

APP_TOML=$NODE_HOME/config/app.toml
CONFIG_TOML=$NODE_HOME/config/config.toml

sed -i "s/minimum-gas-prices = .*/minimum-gas-prices = \"0.005uxprt\"/" $APP_TOML
sed -i "s/persistent_peers = .*/persistent_peers = \"137818b03a705cf86622b4d97a074091f2f22589@185.225.233.30:26756\"/" $CONFIG_TOML
sed -i "s|rpc_servers = .*|rpc_servers = \"https://stargaze-rpc.polkachu.com:443,https://rpc.stargaze-apis.com:443,https://stargaze-rpc.ibs.team:443\"|" $CONFIG_TOML

echo -ne "\e[32m"
sed -n '/^minimum-gas-prices =/p' $APP_TOML
sed -n '/^persistent_peers =/p' $CONFIG_TOML
sed -n '/^rpc_servers =/p' $CONFIG_TOML
echo -ne "\e[0m"
