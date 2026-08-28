#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri <danascape@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
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

# Fills SW_SEARCH_DIRS with the directories searched for device
# configs, highest priority first.
#
# build and doctor have to agree on this order, otherwise doctor
# reports settings from a config that build would never pick up.
sw_config_search_dirs()
{
	SW_SEARCH_DIRS=("$PWD")
	[[ -n "$SW_CONFIG_DIR" ]] && SW_SEARCH_DIRS+=("$SW_CONFIG_DIR")
	SW_SEARCH_DIRS+=("$PWD/configs")
}

# Finds the config file for a device within SW_SEARCH_DIRS.
#
# The declarative .toml wins over the legacy bash .config inside a
# directory, but directory priority still comes first, so a config in
# the kernel tree keeps overriding an installed one either way.
#
# Returns:
# The path on stdout, or nothing when the device has no config.
sw_find_config()
{
	local -r device="$1"
	local dir

	for dir in "${SW_SEARCH_DIRS[@]}"; do
		if [[ -f "$dir/sworkflow.${device}.toml" ]]; then
			echo "$dir/sworkflow.${device}.toml"
			return 0
		elif [[ -f "$dir/sworkflow.${device}.config" ]]; then
			echo "$dir/sworkflow.${device}.config"
			return 0
		fi
	done
	return 1
}

# Loads a device config into the current shell.
#
# A .toml is parsed as data by swconfig.py and never sourced, so a
# config file cannot run code; eval only ever sees swconfig's own
# quoted output.
sw_load_config()
{
	local -r config_file="$1"
	local resolved
	local -a search_args=()
	local dir

	if [[ "$config_file" != *.toml ]]; then
		# shellcheck source=/dev/null
		. "$config_file"
		return
	fi

	for dir in "${SW_SEARCH_DIRS[@]}"; do
		search_args+=(--search "$dir")
	done

	if ! resolved="$(python3 "$SW_SRC_DIR"/utils/swconfig.py "$config_file" \
		"${search_args[@]}" --kernel-root "$PWD")"; then
		return 1
	fi

	eval "$resolved"
}

# Checks if out directory contains the kernel image
#
# Returns:
# True if given kernel image is present and false otherwise
is_kernel_image_present()
{
	local -r DEVICE_ARCH="$1"
	local -r OBJ="$2"
	local -r OUT_DIR_PATH="${OUT_DIR:-out}"

	if [[ -f "${OUT_DIR_PATH}/arch/${DEVICE_ARCH}/boot/${OBJ}" ]]; then
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
