#!/bin/bash
set -e
source ~/.profile

report="VM report"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Load,Processes)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Memory)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Disk)"
report="$report\n\tUsage of **/.node-home: $(du -hs $NODE_HOME | cut -f1)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=LoggedInUsers)"
report="$report\n\t$(landscape-sysinfo --sysinfo-plugins=Temperature)"
report="$report\n$($DAEMON_NAME query slashing signing-info $($DAEMON_NAME tendermint show-validator) | grep 'missed')"

curlCommand="curl -H 'Content-Type: application/json' -d '{\"username\": \"$(hostname)\", \"content\": $(echo -e "$report" | jq -Rsa)}' https://discord.com/api/webhooks/1106459200525180949/91sf8zCkxBD5R9i4UmGXl2oMNYGZJO_yW1vPKQ39Oo35UvhcJgyCzKF6kMi4_putGEs_"
bash -c "$curlCommand"
