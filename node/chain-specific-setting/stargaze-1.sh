#!/bin/bash
set -e

APP_TOML=$NODE_HOME/config/app.toml
CONFIG_TOML=$NODE_HOME/config/config.toml

sed -i "s/minimum-gas-prices = .*/minimum-gas-prices = \"1ustars\"/" $APP_TOML
sed -i "s/iavl-cache-size = .*/iavl-cache-size = \"1562500\"/" $APP_TOML
sed -i "s/query_gas_limit = .*/query_gas_limit = \"5000000\"/" $APP_TOML
sed -i "s/memory_cache_size = .*/memory_cache_size = \"1024\"/" $APP_TOML
# sed -i "s/persistent_peers = .*/persistent_peers = \"99576fbb4d03af198118aee7c15663976355daa0@162.19.169.49:13756\"/" $CONFIG_TOML
sed -i "s|rpc_servers = .*|rpc_servers = \"https://stargaze-rpc.polkachu.com:443,https://rpc.stargaze-apis.com:443,https://stargaze-rpc.ibs.team:443\"|" $CONFIG_TOML

echo -ne "\e[32m"
sed -n '/^minimum-gas-prices =/p' $APP_TOML
sed -n '/^iavl-cache-size =/p' $APP_TOML
sed -n '/^query_gas_limit =/p' $APP_TOML
sed -n '/^memory_cache_size =/p' $APP_TOML
# sed -n '/^persistent_peers =/p' $CONFIG_TOML
sed -n '/^rpc_servers =/p' $CONFIG_TOML
echo -ne "\e[0m"
