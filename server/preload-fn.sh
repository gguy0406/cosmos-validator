#!/bin/bash
function echoc { echo -e "\e[36m$1\e[0m"; }
function echog { echo -e "\e[32m$1\e[0m"; }
function echor { echo -e "\e[31m$1\e[0m"; }
function echoy { echo -e "\e[33m$1\e[0m"; }

function monitorService {
	landscape-sysinfo
	systemctl status --no-pager -n 0 $DAEMON_NAME
	journalctl -f -o cat -u $DAEMON_NAME
}

function executeScript {
	while getopts ":t" option; do
		case $option in
			t) GHP_TOKEN=$OPTARG; export GHP_TOKEN; source ~/.profile;;
			\?) echo "Error: Invalid option"; return 1;;
		esac
	done

	if [[ -z $GHP_TOKEN ]]; then
		read -p "Input token: " GHP_TOKEN

		GHP_TOKEN=$(echo "$GHP_TOKEN" | sed 's/[[:blank:]]//g')

		if [[ -z $GHP_TOKEN ]]; then echo "Error: Invalid input"; return 1; fi

		export GHP_TOKEN
		source ~/.profile
	fi

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
