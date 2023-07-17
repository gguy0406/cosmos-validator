#!/bin/bash
set -e
source ~/.profile

report="VM report"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Load | xargs)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Processes | xargs)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Memory | sed 's/Swap.*//' | xargs)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Disk | xargs)"
report="$report\nNode storage report"
report="$report\n\tapplication.db: $(du -hs $NODE_HOME/data/application.db | cut -f1)"
report="$report\n\tblockstore.db: $(du -hs $NODE_HOME/data/blockstore.db | cut -f1)"
report="$report\n\tstate.db: $(du -hs $NODE_HOME/data/state.db | cut -f1)"
report="$report\nValidator report"
report="$report\n\tMissed in last $SIGNED_BLOCKS_WINDOW blocks: $($DAEMON_NAME q slashing signing-info -o \"json\" $($DAEMON_NAME tendermint show-validator) | jq -r .missed_blocks_counter)"
report="$report\n\tDelegator shares: $(LC_ALL=en_US.UTF-8 printf "%'.3f" $($DAEMON_NAME q staking validator -o \"json\" $VALIDATOR_ADDRESS | jq -r '.delegator_shares | tonumber / 1000000'))"

curlCommand="curl -H 'Content-Type: application/json' -d '{\"username\": \"$(hostname)\", \"content\": $(echo -e "$report" | jq -Rsa)}' $DISCORD_WEBHOOK_URL"
bash -c "$curlCommand"
