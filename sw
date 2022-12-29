#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

# Check for variable
if [[ $SRCDIR ]]; then
	echo ""
else
	echo "error: SRCDIR variable not defined!"
	echo "error: Run setup.sh script and try again."
	exit 1
fi

function sw() {
	argument="$1"

	case "$argument" in
		build)
			(
			echo "Starting build!"
			source $SRCDIR/src/init.sh
		)
		;;
esac
}

sw "$@"
