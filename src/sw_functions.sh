#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

. "$SW_SRC_DIR"/src/sw_color.sh --source-only

## This file contains pre-defined functions that will be used globally inside the tool.

# Checks if a directory is a kernel tree root
#
# @DIR A directory path
#
# Returns:
# True if given dir is a kernel tree root and false otherwise.
is_kernel_root()
{
	local -r DIR="$*"

	# The following files are some of the files expected to be at a linux
	# tree root and not expected to change. Their presence (or abscense)
	# is used to tell if a directory is a linux tree root or not. (They
	# are the same ones used by get_maintainer.pl)
	if [[ -f "${DIR}/COPYING" && -f "${DIR}/CREDITS" && -f "${DIR}/Kbuild" && -e "${DIR}/MAINTAINERS" && -f "${DIR}/Makefile" && -f "${DIR}/README" && -d "${DIR}/Documentation" && -d "${DIR}/arch" && -d "${DIR}/include" && -d "${DIR}/drivers" && -d "${DIR}/fs" && -d "${DIR}/init" && -d "${DIR}/ipc" && -d "${DIR}/kernel" && -d "${DIR}/lib" && -d "${DIR}/scripts" ]]; then
		return 0
	fi
	return 1
}

# Checks if out directory contains the kernel image
#
# Returns:
# True if given kernel image is present and false otherwise
is_kernel_image_present()
{
	local -r DEVICE_ARCH="$1"
	local -r OBJ="$2"

	if [[ -f "out/arch/${DEVICE_ARCH}/boot/${OBJ}" ]]; then
		return 0
	fi
	return 1
}

log_error()
{
	echo "${COLOR_RED}${*}"
}

log_info()
{
	echo "${COLOR_BOLD_BLUE}${*}"
}

log_warnings()
{
	echo "${COLOR_CYAN}${*}"
}
