# How to

First, make sure your system apt library is up-to-date

```bash
sudo apt update && sudo apt full-upgrade -y
```

You may need to reboot after upgrading (if prompted)

```bash
sudo reboot
```

Before executing script from this private repo, you must create yourself a [github personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) and then run the following commands (note that some commands followed by a `source` command in order to load variable exported in `~/.profile` file to the current shell session)

```bash
# Github API
echo -e "\n# Github API" >> ~/.profile
# echo -e "export GH_URL_OPTION=\"-L -H \\\"Accept: application/vnd.github.raw\\\" -H \\\"Authorization: Bearer \$GHP_TOKEN\\\" -H \\\"X-GitHub-Api-Version: 2022-11-28\\\" https://api.github.com/repos/gguy0406/cosmos-validator/contents\"" >> ~/.profile
echo -e "export GH_URL_OPTION=\"-L -H \\\"Accept: application/vnd.github.raw\\\" -H \\\"X-GitHub-Api-Version: 2022-11-28\\\" https://api.github.com/repos/gguy0406/cosmos-validator/contents\"" >> ~/.profile
```

```bash
# Add preload function
read -p "Input token: " GHP_TOKEN
source ~/.profile
mkdir -p ~/minds
cd ~/minds
bash -c "curl --fail-with-body -o ~/minds/preload-fn.sh $GH_URL_OPTION/server/preload-fn.sh"
echo -e "\n# Preload function\nsource ~/minds/preload-fn.sh" >> ~/.profile
source ~/.profile
```

All set, now you can start executing any script by the `executeScript` command, e.g. setup server, load node context

```bash
executeScript server/setup.sh
```

```bash
executeScript server/load-node-context.sh && source ~/.profile
```

```bash
executeScript node/setup.sh
```

# Resources

1. Cosmos chain registry: https://github.com/cosmos/chain-registry/tree/master
2. Cosmos Tutorials: https://tutorials.cosmos.network/academy/1-what-is-cosmos/
3. Cosmos SDK: https://docs.cosmos.network/main
4. Cosmos Hub Document: https://docs.cosmos.network/main
5. Evmos Document: https://docs.evmos.org/validate/setup-and-configuration/faq
6. Other validators: https://polkachu.com, https://app.nodejumper.io
