#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

clone_kernel()
{
	git clone --depth 1 -b master https://github.com/stormbreaker-project/linux-asus-x00p-3.18 X00P
}

clone_toolchains()
{
	git clone --depth=1 https://github.com/stormbreaker-project/aarch64-linux-android-4.9 "$TC_DIR"/gcc > /dev/null 2>&1
	git clone --depth=1 https://github.com/stormbreaker-project/arm-linux-androideabi-4.9 "$TC_DIR"/gcc_32 > /dev/null 2>&1
	git clone --depth=1 -b aosp-11.0.5 https://github.com/sohamxda7/llvm-stable "$TC_DIR"/clang > /dev/null 2>&1
}

compile_kernel()
{
	export PATH="$PWD/tc/clang/bin:$PWD/tc/gcc/bin:$PWD/tc/gcc_32/bin:${PATH}"
	cd X00P || exit 1
	"$WORK_DIR"/sw b X00P-3.18
}

clone_kernel
clone_toolchains
compile_kernel
