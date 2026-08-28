#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri <danascape@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#

. "$SW_SRC_DIR"/src/sw_functions.sh --source-only

# Escapes a value for use inside a TOML basic string.
toml_escape()
{
	local value="$1"

	value="${value//\\/\\\\}"
	value="${value//\"/\\\"}"
	printf '%s' "$value"
}

# Lists the profiles a device can inherit, as `extends` references.
list_profiles()
{
	local dir sub file

	for dir in "${SW_SEARCH_DIRS[@]}"; do
		for sub in base soc; do
			[[ -d "$dir/$sub" ]] || continue
			for file in "$dir/$sub"/*.toml; do
				[[ -f "$file" ]] || continue
				printf '%s/%s\n' "$sub" "$(basename "$file" .toml)"
			done
		done
	done | sort -u
}

generate_config()
{
	local device_name vendor profile
	local device_arch defconfig_arch defconfigs image_name
	local cross_compile cross_compile_arm32 use_clang
	local do_modules create_dist out_dir
	local create_dtbo dtbo_page_size dtbo_path
	local answer config_file entry first
	local -a profiles=() defconfig_list=()

	sw_config_search_dirs

	read -rp "Enter Device Name: " device_name
	if [[ -z "$device_name" ]]; then
		log_error "error: device_name is a required value!"
		log_error "error: Run the script again!"
		exit 125
	fi

	# The name becomes a filename and the key `sw build` looks up, so
	# keep it to something that cannot escape the config directory.
	if [[ ! "$device_name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
		log_error "error: Device name may only contain letters, digits, dot, dash and underscore"
		exit 125
	fi

	config_file="sworkflow.${device_name}.toml"
	if [[ -e "$config_file" ]]; then
		log_error "error: Config for $device_name already present at $PWD/$config_file"
		exit 125
	fi

	read -rp "Enter Device Vendor (optional): " vendor

	while IFS= read -r entry; do
		[[ -n "$entry" ]] && profiles+=("$entry")
	done < <(list_profiles)

	if [[ ${#profiles[@]} -gt 0 ]]; then
		echo ""
		echo "Profiles available to inherit from:"
		for entry in "${profiles[@]}"; do
			echo "  $entry"
		done
		read -rp "Inherit from profile (blank for none): " profile

		if [[ -n "$profile" ]]; then
			# shellcheck disable=SC2076
			if [[ ! " ${profiles[*]} " =~ " ${profile} " ]]; then
				log_error "error: Unknown profile: $profile"
				exit 125
			fi
		fi
		echo ""
	fi

	# A profile already carries the architecture and toolchain, so only
	# ask for them when the device is starting from nothing.
	if [[ -z "$profile" ]]; then
		read -rp "Enter Device Architecture: " device_arch
		if [[ -z "$device_arch" ]]; then
			log_error "error: device architecture is a required value!"
			exit 125
		fi

		read -rp "Does your device have a separate kernel architecture? (y/n) " answer
		if [[ $answer =~ ^[Yy] ]]; then
			read -rp "Enter Kernel Architecture: " defconfig_arch
		fi

		read -rp "Does your kernel need a separate Cross Compiler? (y/n) " answer
		if [[ $answer =~ ^[Yy] ]]; then
			read -rp "Enter Kernel Cross Compiler(64): " cross_compile
			read -rp "Enter Kernel Cross Compiler(32): " cross_compile_arm32
		fi

		read -rp "Does your kernel use clang? (y/n) " answer
		[[ $answer =~ ^[Yy] ]] && use_clang=1
	fi

	read -rp "Enter Device Defconfig (space separated for fragments): " defconfigs
	if [[ -z "$defconfigs" ]]; then
		log_error "error: kernel defconfig is a required variable!"
		log_error "error: Run the script again!"
		exit 125
	fi
	read -ra defconfig_list <<< "$defconfigs"

	read -rp "Enter Kernel Image name (optional, e.g. Image.gz-dtb): " image_name

	read -rp "Do you want to install kernel modules? (y/n) " answer
	[[ $answer =~ ^[Yy] ]] && do_modules=1

	read -rp "Do you want a dist directory of build artifacts? (y/n) " answer
	[[ $answer =~ ^[Yy] ]] && create_dist=1

	read -rp "Does your device need DTBO? (y/n) " answer
	if [[ $answer =~ ^[Yy] ]]; then
		create_dtbo=1
		read -rp "Enter DTBO Page Size: " dtbo_page_size
		if [[ ! "$dtbo_page_size" =~ ^[0-9]+$ ]]; then
			log_error "error: DTBO page size must be a number"
			exit 125
		fi
		read -rp "Enter DTBO path relative to the output directory: " dtbo_path
	fi

	read -rp "Enter output directory (default: out): " out_dir

	log_info "sworkflow: Generating Config..."

	{
		printf 'schema = 1\n'
		[[ -n "$profile" ]] && printf 'extends = "%s"\n' "$(toml_escape "$profile")"

		printf '\n[device]\n'
		printf 'name = "%s"\n' "$(toml_escape "$device_name")"
		[[ -n "$vendor" ]] && printf 'vendor = "%s"\n' "$(toml_escape "$vendor")"

		printf '\n[kernel]\n'
		[[ -n "$device_arch" ]] && printf 'arch = "%s"\n' "$(toml_escape "$device_arch")"
		[[ -n "$defconfig_arch" ]] && printf 'defconfig_arch = "%s"\n' "$(toml_escape "$defconfig_arch")"

		printf 'defconfigs = ['
		first=1
		for entry in "${defconfig_list[@]}"; do
			[[ $first -eq 1 ]] || printf ', '
			printf '"%s"' "$(toml_escape "$entry")"
			first=0
		done
		printf ']\n'
		[[ -n "$image_name" ]] && printf 'image = "%s"\n' "$(toml_escape "$image_name")"

		if [[ -n "$cross_compile" || -n "$cross_compile_arm32" || -n "$use_clang" ]]; then
			printf '\n[toolchain]\n'
			[[ -n "$cross_compile" ]] && printf 'cross_compile = "%s"\n' "$(toml_escape "$cross_compile")"
			[[ -n "$cross_compile_arm32" ]] && printf 'cross_compile_arm32 = "%s"\n' "$(toml_escape "$cross_compile_arm32")"
			[[ -n "$use_clang" ]] && printf 'clang = true\n'
		fi

		if [[ -n "$do_modules" || -n "$create_dist" || -n "$out_dir" ]]; then
			printf '\n[build]\n'
			[[ -n "$do_modules" ]] && printf 'modules = true\n'
			[[ -n "$create_dist" ]] && printf 'dist = true\n'
			[[ -n "$out_dir" ]] && printf 'out_dir = "%s"\n' "$(toml_escape "$out_dir")"
		fi

		if [[ -n "$create_dtbo" ]]; then
			printf '\n[dtbo]\n'
			printf 'enabled = true\n'
			[[ -n "$dtbo_page_size" ]] && printf 'page_size = %s\n' "$dtbo_page_size"
			[[ -n "$dtbo_path" ]] && printf 'path = "%s"\n' "$(toml_escape "$dtbo_path")"
		fi
	} > "$config_file"

	# Hand back nothing the loader would refuse: run the generated file
	# through the same strict check `sw build` applies, so a bad answer
	# surfaces here instead of at the start of a build.
	if ! validate_config "$config_file"; then
		log_error "error: Generated config did not pass validation"
		log_error "error: Fix or remove ${PWD}/${config_file} and try again"
		exit 1
	fi

	log_info "sworkflow: Config Created at ${PWD}/${config_file}"
}

# Checks a config against the schema, resolving `extends` the same way
# the build does.
validate_config()
{
	local -r config_file="$1"
	local -a search_args=()
	local dir

	for dir in "${SW_SEARCH_DIRS[@]}"; do
		search_args+=(--search "$dir")
	done

	python3 "$SW_SRC_DIR"/utils/swconfig.py "$config_file" \
		"${search_args[@]}" --kernel-root "$PWD" --check
}
