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

function setupDevice() {

    local TOP=$(getTop)
    if [[ $# = 0 ]]; then
        echo "usage: setDevice [target]" >&2
        return 1
    fi

    local DEVICE="$1"
    cd "$TOP"
    if [[ -n $(find -L $TOP -maxdepth 4 -name "device-$DEVICE.sh") ]]; then
        for dir in device; do
            for f in $(cd "$TOP" && test -d $dir && \
                find -L $TOP -maxdepth 4 -name "device-$DEVICE.sh" | sort); do
                    echo "including $f"; . "$T/$f"
            done
        done
        displayDeviceInfo $DEVICE
    else
        echo "error: Can not locate config for product "$DEVICE""
    fi
}

function displayDeviceInfo() {

    if [[ $# = 0 ]]; then
        echo "usage: displayDeviceInfo [target]" >&2
        return 1
    fi
    local DEVICE="$1"
    local TARGET_DEVICE="$DEVICE"
    echo "============================================"
    echo "TARGET_DEVICE=$TARGET_DEVICE"
    echo "TARGET_ARCH=arm64" # HardCode this for now.
    echo "KERNEL_DEFCONFIG=$KERNEL_DEFCONFIG"
    echo "KERNEL_DIR=$KERNEL_DIR"
    echo "OUT_DIR=out" # HardCode this for now.
    echo "============================================"
}