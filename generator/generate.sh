#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

read -p "Do you want to generate sworkflow config? (y/n)" answer

generate_config() {
	read -p "Enter Device Name: " device_name

	read -p "Enter Device Architecture: " device_arch

	read -p "Does your device have a separate kernel architecture?" answer
	if [[ $answer =~ ^[Yy]$ ]]; then
		read -p "Enter Kernel Architecture: " kernel_arch
	fi

	read -p "Enter Device Defconfig: " kernel_defconfig

	read -p "Enter Kernel Cross Compiler(64): " cross_compile
	read -p "Enter Kernel Cross Compiler(32): " cross_compile_32

	read -p "Does your kernel use clang? (y/n)" answer
	if [[ $answer =~ ^[Yy] ]]; then
		use_clang=1
	fi

	read -p "Do your device need DTBO? (y/n)" answer
	if [[ $answer =~ ^[Yy] ]]; then
		create_dtbo=1
		read -p "Enter DTBO Page Size: " dtbo_page_size
		read -p "Enter DTBO Path relative to outdir: " dtbo_arch_path
	fi

	echo "sworkflow: Config Created..."
}
if [[ $answer =~ ^[Yy]$ ]]; then
	echo "sworkflow: Starting the daemon..."
	sleep 2
	clear
	generate_config
else
	echo "sworkflow: Exiting..."
	exit 125
fi
