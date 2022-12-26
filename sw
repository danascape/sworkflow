#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

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
