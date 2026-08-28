#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri <danascape@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#

. "$SW_SRC_DIR"/src/build_vars.sh --source-only
. "$SW_SRC_DIR"/src/sw_functions.sh --source-only

# Check if the kernel config already exists for a particular device.
# Search order: 1) Current directory 2) SW_CONFIG_DIR 3) ./configs/
#
# Within a directory the declarative .toml config wins over the legacy
# bash .config, so converting a device is enough to switch it over while
# a config the user has only in the old format keeps working.
check_kernel()
{
	local device="$1"
	local found_config=""
	local dir
	SWORKFLOW_CONFIG=""
	SW_SEARCH_DIRS=()

	if [[ -z "$device" ]]; then
		log_error "error: Device name is empty!"
		exit 125
	fi

	log_info "sworkflow: Checking if kernel config exists for $device"

	SW_SEARCH_DIRS+=("$(pwd)")
	[[ -n "$SW_CONFIG_DIR" ]] && SW_SEARCH_DIRS+=("$SW_CONFIG_DIR")
	SW_SEARCH_DIRS+=("$(pwd)/configs")

	for dir in "${SW_SEARCH_DIRS[@]}"; do
		if [[ -f "$dir/sworkflow.${device}.toml" ]]; then
			found_config="$dir/sworkflow.${device}.toml"
			break
		elif [[ -f "$dir/sworkflow.${device}.config" ]]; then
			found_config="$dir/sworkflow.${device}.config"
			break
		fi
	done

	if [[ -z "$found_config" ]]; then
		log_error "error: No config file found for device: $device"
		log_error "error: Searched in:"
		for dir in "${SW_SEARCH_DIRS[@]}"; do
			log_error "       - $dir/"
		done
		exit 125
	fi

	SWORKFLOW_CONFIG="$found_config"
	log_info "sworkflow: Including $found_config"

	if [[ "$found_config" == *.toml ]]; then
		load_toml_config "$found_config"
	else
		# shellcheck source=/dev/null
		. "$found_config"
	fi
}

# Resolve a declarative config into shell variables.
#
# The file is parsed as data and never sourced, so a config cannot run
# code. swconfig.py prints the assignments and eval only ever sees its
# own quoted output.
load_toml_config()
{
	local config_file="$1"
	local resolved
	local -a search_args=()
	local dir

	for dir in "${SW_SEARCH_DIRS[@]}"; do
		search_args+=(--search "$dir")
	done

	if ! resolved="$(python3 "$SW_SRC_DIR"/utils/swconfig.py "$config_file" \
		"${search_args[@]}" --kernel-root "$PWD")"; then
		log_error "error: Could not load $config_file"
		exit 125
	fi

	eval "$resolved"
}

do_anykernel()
{
	branch="$1"
	ANYKERNEL_LINK="https://github.com/stormbreaker-project/AnyKernel3"
	if [[ -d "AnyKernel3" ]]; then
		log_info "sworkflow: AK3 already present"
		log_info "warning: Skipping Clone"
	else
		git clone -b "$branch" "$ANYKERNEL_LINK" --depth=1 AnyKernel3
	fi
	cd AnyKernel3/ || log_error "error: Directory not Found"
	make clean
	cp -r ../"${OUT_DIR}/dist/"* ./
	make
}

do_kernel_modules()
{
	if [[ -d "${OUT_DIR}/dist/modules" ]]; then
		log_info "sworkflow: Removing old modules"
		rm -rf "${OUT_DIR}/dist/modules"
	fi
	mkdir -p "${OUT_DIR}/dist/modules"

	local modules_dir="${OUT_DIR}/modules/lib/modules/${kernel_release}"

	modules=()

	while IFS= read -r -d $'\0' file; do
		modules+=("$file")
	done < <(find "$modules_dir" -name '*.ko' -print0)

	for file in "${modules[@]}"; do
		cp "$file" "$dist_path/modules/"
	done

	cp "$modules_dir"/modules.{alias,dep,softdep} "$dist_path"/modules
	cp "$modules_dir"/modules.order "$dist_path"/modules/modules.load
	sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' "$dist_path"/modules/modules.dep
	sed -i 's/.*\///g' "$dist_path"/modules/modules.load

}

install_ext_modules()
{
	local ext_mod_entry mod_path mod_type abs_mod_path rpath
	local -a ext_mod_list

	read -ra ext_mod_list <<< "$ext_modules"

	for ext_mod_entry in "${ext_mod_list[@]}"; do
		mod_path="${ext_mod_entry%%:*}"
		mod_type="${ext_mod_entry#*:}"
		if [[ "$mod_type" == "$mod_path" ]]; then
			mod_type=""
		fi
		abs_mod_path="${ext_modules_root:+$ext_modules_root/}$mod_path"
		rpath="$(python3 -c 'import os,sys;print(os.path.relpath(*(sys.argv[1:])))' "$abs_mod_path" "$PWD")"

		log_info "sworkflow: Installing external module: $abs_mod_path"
		if [[ "$mod_type" == "kbuild" ]]; then
			if ! make -C "$PWD" M="$abs_mod_path" O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}" INSTALL_MOD_PATH="$OUT_DIR/modules" INSTALL_MOD_STRIP=1 KERNEL_UAPI_HEADERS_DIR="$OUT_DIR" modules_install; then
				log_error "error: External module install failed: $abs_mod_path"
				exit 1
			fi
		else
			if ! make -C "$abs_mod_path" M="$rpath" KERNEL_SRC="$PWD" OUT_DIR="$OUT_DIR" O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}" INSTALL_MOD_PATH="$OUT_DIR/modules" INSTALL_MOD_STRIP=1 KERNEL_UAPI_HEADERS_DIR="$OUT_DIR" modules_install; then
				log_error "error: External module install failed: $abs_mod_path"
				exit 1
			fi
		fi
	done
}

build_ext_modules()
{
	local ext_mod_entry mod_path mod_type abs_mod_path rpath
	local -a ext_mod_list

	read -ra ext_mod_list <<< "$ext_modules"

	for ext_mod_entry in "${ext_mod_list[@]}"; do
		mod_path="${ext_mod_entry%%:*}"
		mod_type="${ext_mod_entry#*:}"
		if [[ "$mod_type" == "$mod_path" ]]; then
			mod_type=""
		fi
		abs_mod_path="${ext_modules_root:+$ext_modules_root/}$mod_path"
		rpath="$(python3 -c 'import os,sys;print(os.path.relpath(*(sys.argv[1:])))' "$abs_mod_path" "$PWD")"

		if [[ ! -d "$abs_mod_path" ]]; then
			log_error "error: External module path not found: $abs_mod_path"
			exit 1
		fi

		log_info "sworkflow: Building external module: $abs_mod_path"
		if [[ "$mod_type" == "kbuild" ]]; then
			if ! make -C "$PWD" M="$abs_mod_path" O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}"; then
				log_error "error: External module build failed: $abs_mod_path"
				exit 1
			fi
		else
			if ! make -C "$abs_mod_path" M="$rpath" KERNEL_SRC="$PWD" OUT_DIR="$OUT_DIR" O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}"; then
				log_error "error: External module build failed: $abs_mod_path"
				exit 1
			fi
		fi

		if [[ -f "$abs_mod_path/Module.symvers" ]]; then
			cat "$abs_mod_path/Module.symvers" >> "$OUT_DIR/Module.symvers"
		fi
	done
}

displayDeviceInfo()
{

	if [[ $# = 0 ]]; then
		log_info "usage: displayDeviceInfo [target]" >&2
		return 1
	fi

	local DEVICE
	local TARGET_DEVICE
	local HOST_OS
	local HOST_OS_EXTRA

	DEVICE="$1"
	TARGET_DEVICE="$DEVICE"
	HOST_OS="$(uname)"
	HOST_OS_EXTRA="$(uname -r)"

	log_info "============================================"
	log_info "TARGET_DEVICE=$TARGET_DEVICE"
	log_info "TARGET_ARCH=$device_arch"
	log_info "KERNEL_DEFCONFIG=$kernel_defconfig"
	log_info "KERNEL_DIR=$PWD"
	log_info "HOST_OS=$HOST_OS"
	log_info "HOST_OS_EXTRA=$HOST_OS_EXTRA"
	log_info "HOST_PATH=$PATH"
	log_info "OUT_DIR=$OUT_DIR"
	log_info "SWORKFLOW_CONFIG=$SWORKFLOW_CONFIG"
	if [[ -n "$board_platform" ]]; then
		log_info "BOARD_PLATFORM=$board_platform"
	fi
	if [[ -n "$ext_modules" ]]; then
		log_info "EXT_MODULES=$ext_modules"
		if [[ -n "$ext_modules_root" ]]; then
			log_info "EXT_MODULES_ROOT=$ext_modules_root"
		fi
	fi
	log_info "============================================"
}

kernel_build()
{
	device="$3"
	check_kernel "$device"
	log_info "sworkflow: Starting Kernel Build!"
	OUT_DIR="${out_dir:-out}"
	[[ "$OUT_DIR" != /* ]] && OUT_DIR="$PWD/$OUT_DIR"
	export OUT_DIR

	if [[ -n "$board_platform" ]]; then
		export TARGET_BOARD_PLATFORM="$board_platform"
	fi

	if [[ -n "$(command -v nproc)" ]]; then
		parallel_threads="$(nproc --all)"
	else
		parallel_threads="$(grep -c ^processor /proc/cpuinfo)"
	fi

	if ! is_kernel_root "$PWD"; then
		log_error "error: Execute this command in a kernel tree."
		exit 125
	fi

	if [[ -n "$build_silent" ]]; then
		MAKE+=(-s)
	fi

	if [[ -n "$cross_compile" ]]; then
		cross_compile="CROSS_COMPILE=$cross_compile"
		MAKE+=("$cross_compile")
	fi

	if [[ -n "$cross_compile_arm32" ]]; then
		cross_compile_arm32="CROSS_COMPILE_ARM32=$cross_compile_arm32"
		MAKE+=("$cross_compile_arm32")
	fi

	if [[ -n "$use_clang" ]]; then
		cc="CC=clang"
		case "$device_arch" in
			arm64) clang_triple="CLANG_TRIPLE=aarch64-linux-gnu-" ;;
			arm) clang_triple="CLANG_TRIPLE=arm-linux-gnu-" ;;
			x86*) clang_triple="CLANG_TRIPLE=x86_64-linux-gnu-" ;;
			*) clang_triple="CLANG_TRIPLE=aarch64-linux-gnu-" ;;
		esac
		MAKE+=("$cc" "$clang_triple")
	fi

	if [[ -z "$device_arch" ]]; then
		log_error "error: Device architecture not defined!"
		exit 22
	fi

	if [[ -z "$kernel_defconfig" ]]; then
		log_error "error: Device Defconfig not defined!"
		exit 22
	fi

	# Split kernel_defconfig into an array
	read -ra defconfigs <<< "$kernel_defconfig"

	local configs_arch="${kernel_arch:-$device_arch}"
	if [[ ! -f "arch/$configs_arch/configs/${defconfigs[0]}" ]]; then
		log_error "error: Device Defconfig not found: ${defconfigs[0]}"
		exit 22
	fi

	displayDeviceInfo "$device"

	if ! make O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}" "${defconfigs[@]}"; then
		log_error "error: Defconfig step failed!"
		exit 1
	fi

	if [[ -n "$build_clean" ]]; then
		make O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" clean
		make O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" mrproper
	fi

	start=$(date +%s)

	if ! make O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}"; then
		log_error "error: Kernel build failed!"
		exit 1
	fi

	if [[ -n "$ext_modules" ]]; then
		build_ext_modules
	fi

	if [[ -n "$do_modules" ]]; then
		log_info "sworkflow: Installing modules"
		make O="$OUT_DIR" -j"$parallel_threads" ARCH="$device_arch" "${MAKE[@]}" INSTALL_MOD_PATH=modules INSTALL_MOD_STRIP=1 modules_install

		if [[ -n "$ext_modules" ]]; then
			install_ext_modules
		fi

		if [[ ! -f "$OUT_DIR/System.map" ]]; then
			log_error "error: System.map not found, cannot run depmod"
			exit 1
		fi

		kernel_release="$(cat "$OUT_DIR/include/config/kernel.release")"

		dup_modules="$(find "$OUT_DIR/modules/lib/modules/$kernel_release" -name '*.ko' -print0 | xargs -0 -I{} basename {} | sort | uniq -d)"
		if [[ -n "$dup_modules" ]]; then
			log_error "error: Duplicate kernel modules found:"
			while IFS= read -r mod; do
				log_error "       $mod"
			done <<< "$dup_modules"
			exit 1
		fi
		log_info "sworkflow: Running depmod for $kernel_release"
		depmod_stderr="$(mktemp)"
		depmod -ae -F "$OUT_DIR/System.map" -b "$OUT_DIR/modules" "$kernel_release" 2> "$depmod_stderr"
		if grep -q "needs unknown symbol" "$depmod_stderr"; then
			cat "$depmod_stderr" >&2
			rm -f "$depmod_stderr"
			log_error "error: Kernel modules need unknown symbols"
			exit 1
		fi
		cat "$depmod_stderr" >&2
		rm -f "$depmod_stderr"

		if grep -q "CONFIG_MODULE_SIG_FORMAT=y" "$OUT_DIR/.config"; then
			log_info "sworkflow: Signing kernel modules"
			sign_file="$OUT_DIR/scripts/sign-file"
			sign_key="$OUT_DIR/certs/signing_key.pem"
			sign_cert="$OUT_DIR/certs/signing_key.x509"
			if [[ ! -x "$sign_file" || ! -f "$sign_key" || ! -f "$sign_cert" ]]; then
				log_error "error: Module signing requested but sign-file or keys not found"
				exit 1
			fi
			while IFS= read -r -d $'\0' ko; do
				"$sign_file" sha1 "$sign_key" "$sign_cert" "$ko" || {
					log_error "error: Failed to sign $ko"
					exit 1
				}
			done < <(find "$OUT_DIR/modules" -name '*.ko' -print0)
		fi
	fi

	if [[ -n "$create_dtbo" ]]; then
		log_info "sworkflow: Creating dtbo"
		dtbo_path="${OUT_DIR}/arch/$device_arch/boot/dtbo.img"
		if [[ -f $dtbo_path ]]; then
			log_warning "warning: DTBO image already present!"
		else
			if [[ -n "$dtbo_page_size" ]]; then
				if [[ -n $dtbo_arch_path ]]; then
					python3 "$SW_SRC_DIR"/utils/mkdtboimg.py create "${OUT_DIR}/arch/$device_arch/boot/dtbo.img" --page_size="$dtbo_page_size" "$dtbo_arch_path"
				else
					log_error "error: kernel DTBO directory not defined!"
					exit 22
				fi
			else
				log_error "error: DTBO page size not defined!"
				exit 22
			fi
		fi
	fi

	if [[ -n "$create_dist" ]]; then
		if [[ -n "$kernel_image_name" ]]; then
			log_info "sworkflow: Checking kernel image!"
			if ! is_kernel_image_present "$device_arch" "$kernel_image_name"; then
				log_error "error: Build failed"
			else
				log_info "sworkflow: Creating dist directory"
				mkdir -p "${OUT_DIR}/dist"
				dist_path="${OUT_DIR}/dist"
				log_info "sworkflow: Copying the contents into dist"
				kernel_image_path="${OUT_DIR}/arch/$device_arch/boot/$kernel_image_name"
				cp "$kernel_image_path" "$dist_path"
				if [[ -n "$do_modules" ]]; then
					log_info "sworkflow: Copying modules"
					do_kernel_modules
				fi
			fi
		else
			log_error "error: Define $kernel_image_name to create dist"
		fi
	fi

	if [[ -n "$do_anykernel" ]]; then
		if [[ -n "$anykernel_branch" ]]; then
			log_info "sworkflow: Cloning Anykernel3"
			do_anykernel "$anykernel_branch"
		else
			log_error "error: Define Anykernel Branch!"
			log_error "error: Check Documentation for more"
		fi
	fi

	end=$(date +%s)

	time=$((end - start))
	elapsed_time=$(date -d@"$time" -u +%H:%M:%S)
	log_info "-> sworkflow: Execution time: $elapsed_time"
}

parse_build_arguments()
{
	if [[ "$?" != 0 ]]; then
		return 22 # EINVAL
	fi

	while [[ "$#" -gt 0 ]]; do
		case "$1" in
			*)
				log_error "error: Invalid Argument"
				exit 22 # EINVAL
				;;
		esac
	done
}
