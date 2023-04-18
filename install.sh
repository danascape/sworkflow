#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

## source code directories
declare -r SRCDIR=$(pwd)

source $SRCDIR/sw

function safe_append()
{
  if [[ $(grep -c -x "$1" "$2") == 0 ]]; then
    printf '%s\n' "$1" >> "$2"
  fi
}

update_path() {
	local shellrc 
	shellrc=${1:-'.bashrc'}
	
	IFS=':' read -ra ALL_PATHS <<< "$PATH"
	for path in "${ALL_PATHS[@]}"; do
		[[ "$path" -ef "$binpath" ]] && return
	done
	
	# We are installing sworkflow in home directory
	# Do not delete this directory
	safe_append "PATH=${HOME}/sworkflow:\$PATH # sw" "${HOME}/${shellrc}"
}

update_path
