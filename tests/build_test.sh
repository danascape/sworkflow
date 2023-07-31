#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

cd "$HOME" || exit 1
mkdir tc
export TC_DIR="$HOME/tc"
export WORK_DIR="$HOME/sworkflow"
cd "$WORK_DIR" || exit 1
#bash install.sh
#source ~/.bashrc

cd "$HOME" || exit 1
git clone --depth 1 -b master https://github.com/stormbreaker-project/linux-asus-x00p-3.18 X00P
git clone --depth=1 https://github.com/stormbreaker-project/aarch64-linux-android-4.9 "$TC_DIR"/gcc >/dev/null 2>&1
git clone --depth=1 https://github.com/stormbreaker-project/arm-linux-androideabi-4.9 "$TC_DIR"/gcc_32 >/dev/null 2>&1
git clone --depth=1 -b aosp-11.0.5 https://github.com/sohamxda7/llvm-stable "$TC_DIR"/clang >/dev/null 2>&1
export PATH="$HOME/tc/clang/bin:$HOME/tc/gcc/bin:$HOME/tc/gcc_32/bin:${PATH}"
cd X00P || exit 1
"$HOME"/sworkflow/sw b X00P
