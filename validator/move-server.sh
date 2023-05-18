#!/bin/bash
set -e
ssh $2 "mkdir -p backup"
ssh $1 -t "source .profile; executeScript validator/stop-validating.sh -t $GHP_TOKEN || bash"
scp $1:~/backup/priv_validator_key.json $2:~/backup
scp $1:~/backup/priv_validator_state.json $2:~/backup
ssh $2 -t "source .profile; executeScript validator/start-validating-from-backup.sh -t $GHP_TOKEN; bash"
