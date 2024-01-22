# How to

First, make sure your system apt library is up-to-date

```bash
sudo apt update && sudo apt full-upgrade -y
```

You may need to reboot after upgrading (if prompted)

```bash
sudo reboot
```

Get some utility scripts

```bash
# Add profile script
echo -e "\n# Github API" >> ~/.profile
echo -e "export GH_URL_OPTION=\"-L -H \\\"Accept: application/vnd.github.raw\\\" -H \\\"X-GitHub-Api-Version: 2022-11-28\\\" https://api.github.com/repos/gguy0406/cosmos-validator/contents\"" >> ~/.profile
source ~/.profile
echo -e "\n# Preload function\nsource ~/minds/util-fn.sh" >> ~/.profile

# Get script
sudo apt install -y curl landscape-common
mkdir -p ~/minds
bash -c "curl --fail-with-body -o ~/minds/util-fn.sh $GH_URL_OPTION/server/util-fn.sh"
source ~/.profile
```

All set, now you can start executing any script by the `executeScript` command, e.g. setup server, load node context

```bash
executeScript server/config-firewall.sh
executeScript node/load-context.sh && source ~/.profile
```

```bash
executeScript node/setup-binary.sh
```

In case state sync module fail and need to rerun, recheck rpc servers and execute following script

```bash
executeScript node/reset-state-sync.sh 1000
```

Setup background service

```bash
executeScript node/setup-bg-service.sh
```

# Resources

1. Cosmos chain registry: https://github.com/cosmos/chain-registry/tree/master
2. Cosmos Tutorials: https://tutorials.cosmos.network/academy/1-what-is-cosmos/
3. Cosmos SDK: https://docs.cosmos.network/main
4. Cosmos Hub Document: https://docs.cosmos.network/main
