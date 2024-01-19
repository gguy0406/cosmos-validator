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
echo -e "\n# Preload function\nsource ~/minds/preload-fn.sh" >> ~/.profile

# Get script
sudo apt install -y curl landscape-common
mkdir -p ~/minds
bash -c "curl --fail-with-body -o ~/minds/preload-fn.sh $GH_URL_OPTION/server/preload-fn.sh"
source ~/.profile
```

All set, now you can start executing any script by the `executeScript` command, e.g. setup server, load node context

```bash
executeScript server/setup.sh
executeScript server/load-node-context.sh && source ~/.profile
```

After checking all parameter set correctly

```bash
executeScript node/setup.sh
```

# Resources

1. Cosmos chain registry: https://github.com/cosmos/chain-registry/tree/master
2. Cosmos Tutorials: https://tutorials.cosmos.network/academy/1-what-is-cosmos/
3. Cosmos SDK: https://docs.cosmos.network/main
4. Cosmos Hub Document: https://docs.cosmos.network/main
