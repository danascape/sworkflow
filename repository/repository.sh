#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

if [[ $# = 0 ]]; then
    echo "usage: ./repository.sh [target]" >&2
    return 1
fi

# Set Default Variables
GITHUB_ORG_lINK="https://github.com/stormbreaker-project"
DEVICE="$1"
KERNEL_DIR="$2"

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

# Clone the device repository
function cloneDevice() {
    local TOP=$(getTop)

    echo "warning: Attempting to clone device repository"

    git clone --depth=1 $GITHUB_ORG_lINK/$DEVICE $TOP/$KERNEL_DIR  >/dev/null 2>&1 || cloneError
    if [[ -f $KERNEL_DIR/Makefile ]]; then
        echo "warning: Kernel source synced at $KERNEL_DIR"
    else
        echo ""
        echo "error: Something went wrong while cloning."
        echo ""
        exit 1
    fi
}

function cloneError() {
    echo "error: Failed to clone Device Kernel Source"
    echo "error: This can be caused due to the device not being maintained"
}

cloneDevice