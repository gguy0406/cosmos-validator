#!/bin/bash
set -e
report="VM report\n$(echo $(landscape-sysinfo --sysinfo-plugins=Disk,Memory,Temperature,LoggedInUsers))"
curlCommand="curl -H 'Content-Type: application/json' -d '{\"username\": \"$(hostname)\", \"content\": $(echo -e "$report" | jq -Rsa)}' https://discord.com/api/webhooks/1106459200525180949/91sf8zCkxBD5R9i4UmGXl2oMNYGZJO_yW1vPKQ39Oo35UvhcJgyCzKF6kMi4_putGEs_"
bash -c "$curlCommand"
