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
        local HERE=$PWD
        local T=
        while [ \( ! \( -f $TOPFILE \) \) -a \( "$PWD" != "/" \) ]; do
            \cd ..
            T=`PWD= /bin/pwd -P`
        done
            \cd "$HERE"
        if [ -f "$T/$TOPFILE" ]; then
            echo "$T"
        fi
    fi
}