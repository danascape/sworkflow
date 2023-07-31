#!/usr/bin/env bash

#
# Copyright (C) 2019 Saalim Quadri (danascape)
#
# SPDX-License-Identifier: Apache-2.0 license
#

## Color codes that will be used
# red = errors, green = confirmations, cyan = warnings
# bold blue = informational
COLOR_RST=$(tput sgr0)
COLOR_RED=$COLOR_RST$(tput setaf 1)
COLOR_GREEN=$COLOR_RST$(tput setaf 2)
COLOR_CYAN=$COLOR_RST$(tput setaf 6)
COLOR_BOLD=$(tput bold)
COLOR_BOLD_BLUE=$COLOR_RST$COLOR_BOLD$(tput setaf 4)

export COLOR_RED
export COLOR_GREEN
export COLOR_CYAN
export COLOR_BOLD_BLUE
