#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

function getTop() {
    local TOPFILE=build/envsetup.sh
    if [[ -f "$TOPFILE" ]] ; then
        PWD= /bin/pwd
    else
        echo "File not found"
    fi
}