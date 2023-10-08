#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

declare -r app_name='sw'

##
## Following are the install paths
##
# Paths used during the installation process]
declare -r binpath="$HOME/.local/bin"
declare -r srcpath="$HOME/.local/$app_name"
declare -r swbinpath="$HOME/.local/bin/$app_name"

# Source code references
declare -r SRCDIR='src'

safe_append()
{
	if [[ $(grep -c -x "$1" "$2") == 0 ]]; then
		printf '%s\n' "$1" >> "$2"
	fi
}

sworkflow_setup_help()
{
	echo "Usage: ./setup.sh [options]"

	echo -e "\nCommands\n" \
		"\tinstall,i - Install sworkflow\n" \
		"\thelp,h - Print this help message\n"

}

synchronize_files()
{
	echo "sworkflow: Installing files"
	mkdir -p "$binpath"
	mkdir -p "$srcpath"
	cp $app_name "$swbinpath"
	rsync -vr $SRCDIR "$srcpath"

	if [[ -z "$(which bash)" ]]; then
		echo "error: No bash"
	else
		if [[ -f "$HOME/.bashrc" ]]; then
			update_path '.bashrc'
		else
			echo "warning: Unable to find a .bashrc file"
		fi
	fi
}

update_path()
{
	local shellrc=${1:-'.bashrc'}

	IFS=':' read -ra ALL_PATHS <<< "$PATH"
	for path in "${ALL_PATHS[@]}"; do
		[[ "$path" -ef "$binpath" ]] && return
	done

	safe_append "PATH=${HOME}/.local/bin:\$PATH # sw" "${HOME}/${shellrc}"
}

setup()
{
	argument="$1"

	case "$argument" in
		install | i)
			(
				echo "Installing sworkflow"
				synchronize_files
			)
			;;
		help | h)
			(
				sworkflow_setup_help
			)
			;;
		*)
			(
				echo "error: Invalid Option"
				sworkflow_setup_help
			)
			;;
	esac
}

setup "$@"
