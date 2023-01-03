#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

## Global Paths

# SW source directory
SW_SRC_DIR="$HOME/sworkflow"

# Check for variable
if [[ $SW_SRC_DIR ]]; then
	echo "warning: Using hardcode directory is not recommended"
	echo "warning: Refer to https://github.com/danascape/sworkflow/issues/12 for more"
	echo ""
else
	echo "error: SW_SRC_DIR variable not defined!"
	echo "error: Run setup.sh script and try again."
	exit 1
fi

function sw() {
	argument="$1"

	case "$argument" in
		build | b)
			(
			. $SW_SRC_DIR/src/build.sh --source-only

			kernel_build '' "$@"

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
