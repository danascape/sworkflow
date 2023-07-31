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

# Source code references
declare -r SRCDIR='src'

safe_append()
{
	if [[ $(grep -c -x "$1" "$2") == 0 ]]; then
		printf '%s\n' "$1" >> "$2"
	fi
}

synchronize_files()
{
	echo "sworkflow: Installing files"
	mkdir -p "$srcpath"
	rsync -vr $SRCDIR $srcpath
}

update_path()
{
	local shellrc=${1:-'.bashrc'}

	# We are installing sworkflow in home directory
	# Do not delete this directory
	safe_append "PATH=${HOME}/sworkflow:\$PATH # sw" "${HOME}/${shellrc}"
}

setup()
{
	argument="$1"

	case "$argument" in
		install | -i)
			(
				echo "Installing sworkflow"
				synchronize_files
				update_path '.bashrc'
			)
			;;
		*)
			(
				echo "error: Invalid Option"
			)
			;;
	esac
}

setup "$@"
