#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

SWORKFLOW=${SWORKFLOW:-'sw'}

# Global Paths

# SW source directory
if [[ -f '/usr/bin/sw' ]]; then
	SW_SRC_DIR="/usr/share/sw"
elif [[ -f $HOME/sworkflow/sw ]]; then
	SW_SRC_DIR="$HOME/sworkflow"
else
	# SW_SRC_DIR="${SW_SRC_DIR:-"$HOME/.local/sw"}/${SWORKFLOW}"
	SW_SRC_DIR="$HOME/.local/sw"
fi

sw()
{
	argument="$1"

	case "$argument" in
		build | b)
			(
				. $SW_SRC_DIR/src/build.sh --source-only

				kernel_build '' "$@"

			)
			;;
		generate | g)
			(
			. $SW_SRC_DIR/generator/generate.sh
		)
		;;
		help | h)
			(
				. $SW_SRC_DIR/src/help.sh --source-only

				sworkflow_help
			)
			;;
		man | m)
			(
				. $SW_SRC_DIR/src/help.sh --source-only

				sworkflow_help
			)
			;;
		version | v)
			(
				. $SW_SRC_DIR/src/version.sh --source-only

				sworkflow_version
			)
			;;
		*)
			(
				echo "error: Invalid Option"
				. $SW_SRC_DIR/src/help.sh --source-only

				sworkflow_help

			)
			;;

	esac
}

sw "$@"
