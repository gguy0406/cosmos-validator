#!/bin/bash
function echoc { echo -e "\e[36m$1\e[0m"; }
function echog { echo -e "\e[32m$1\e[0m"; }
function echor { echo -e "\e[31m$1\e[0m"; }
function echoy { echo -e "\e[33m$1\e[0m"; }

function monitorService {
	landscape-sysinfo
	systemctl status --no-pager -n 0 $DAEMON_NAME
	sudo journalctl -f -o cat -u $DAEMON_NAME
}

function executeScript {
	GH_SCRIPT=$(bash -c "curl --fail-with-body $GH_URL_OPTION/$1")
	shift
	bash <(echo "$GH_SCRIPT") $@
}

export -f echoc
export -f echog
export -f echor
export -f echoy
export -f monitorService
export -f executeScript
