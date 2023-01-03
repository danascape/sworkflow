#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

. $SW_SRC_DIR/src/build_vars.sh --source-only
. $SW_SRC_DIR/src/sw_functions.sh --source-only


# Check if the kernel config already exists for a particular device.
# This check is being performed to add support for official devices.
function check_kernel() {
	local device
	device="$1"
	echo "Checking if kernel config exists for $device"
	if [[ -n $(find -L $SW_SRC_DIR/device -maxdepth 2 -name "sworkflow.$device.config") ]]; then
		for dir in device; do
			for f in $(cd "$SW_SRC_DIR" && test -d $dir && \
				find -L $SW_SRC_DIR -maxdepth 4 -name "sworkflow.$device.config" | sort); do
				        echo "including $f"; . "$f" --source-only
			done
		done
		echo "warning: sworkflow.$device.config found"
		echo "warning: Exporting the defined variables"
	elif [[ -n $(find -L $(pwd) -maxdepth 2 -name "sworkflow.$device.config") ]]; then
		for dir in device; do
			for f in $(cd $(pwd) && test -d $dir && \
				find -L $(pwd) -maxdepth 4 -name "sworkflow.$device.config" | sort); do
				        echo "including $f"; . "$f" --source-only
			done
		done
		echo $test
		echo "warning: sworkflow.$device.config found outside the tree"
		echo "warning: Exporting the variables"
	else
		echo "error: No config file found"
		echo "error: Refer to docs for more"
		exit 125
	fi

}

function kernel_build() {
	device="$3"
	check_kernel $device
	echo "Starting Kernel Build!"

	if [[ -z "$(which nproc)" ]]; then
		parallel_threads=$(nproc --all)
	else
		parallel_threads=$(grep -c ^processor /proc/cpuinfo)
	fi

	if ! is_kernel_root "$PWD"; then
		echo "Execute this command in a kernel tree."
		exit 125
	fi

	if [[ -n "$cross_compile" ]]; then
		cross_compile="CROSS_COMPILE=$cross_compile"
	fi

	if [[ -n "$cross_compile_arm32" ]]; then
		cross_compile_arm32="CROSS_COMPILE_ARM32=$cross_compile_arm32"
	fi

	make O=out -j$parallel_threads ARCH=$kernel_arch $kernel_defconfig

	command="make O=out -j$parallel_threads ARCH=$kernel_arch $cross_compile $cross_compile_arm32"

	start=$(date +%s)
	
	$command
	
	end=$(date +%s)

	time=$((end - start))

	echo $time


}
