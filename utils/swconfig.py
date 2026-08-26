#! /usr/bin/env python3
#
# SPDX-FileCopyrightText: 2019 Saalim Quadri <danascape@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#

"""Resolve a sworkflow TOML device config into shell assignments.

Reads a sworkflow.<device>.toml file, follows its `extends` chain,
checks it against the schema and prints the result as shell variable
assignments for build.sh to eval. Config files stay data: nothing in
them is ever executed.
"""

import argparse
import os
import re
import shlex
import sys

try:
    import tomllib
except ModuleNotFoundError:  # Python < 3.11
    try:
        import tomli as tomllib
    except ModuleNotFoundError:
        sys.exit("error: TOML configs need python3 >= 3.11 or python3-tomli")

# Bumped only on an incompatible change. A config declaring anything
# else is refused rather than half understood.
SCHEMA_VERSION = 1

# Table name -> accepted key -> accepted type(s). Anything outside this
# is an error, so a typo fails the build instead of silently doing
# nothing the way a stray shell variable used to.
SCHEMA = {
    "device": {
        "name": str, "vendor": str, "aliases": list, "board_platform": str,
    },
    "kernel": {
        "arch": str, "defconfig_arch": str, "defconfigs": list, "image": str,
    },
    "toolchain": {
        "cross_compile": str, "cross_compile_arm32": str,
        "clang": (bool, str), "gcc": str, "env": dict,
    },
    "build": {
        "modules": bool, "dist": bool, "clean": bool, "silent": bool,
        "out_dir": str,
    },
    "dtbo": {"enabled": bool, "page_size": int, "path": str},
    "anykernel": {"enabled": bool, "branch": str},
    "external_modules": {"root": str, "paths": list},
    "meta": {"maintainer": str, "tested_tree": str},
}

EXPANSION = re.compile(r"\$\{([a-z_]+(?:\.[a-zA-Z_][a-zA-Z0-9_]*)?)\}")


def die(msg):
    sys.exit("error: %s" % msg)


def find_parent(name, search_dirs):
    """Resolve an `extends` reference against the config search path."""
    rel = name + ".toml"
    for directory in search_dirs:
        candidate = os.path.join(directory, rel)
        if os.path.isfile(candidate):
            return candidate
    die("cannot resolve extends \"%s\", looked in: %s"
        % (name, ", ".join(search_dirs) or "(nothing)"))


def merge(base, overlay):
    """Overlay a child onto its parent.

    Tables merge key by key so a child only replaces what it names, and
    lists concatenate with the parent's entries first so a device adds
    to a profile's defconfigs or modules instead of restating them.
    """
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            merge(base[key], value)
        elif isinstance(value, list) and isinstance(base.get(key), list):
            base[key] = base[key] + value
        else:
            base[key] = value


def load(path, search_dirs, seen=None):
    seen = list(seen or [])
    real = os.path.realpath(path)
    if real in seen:
        die("extends cycle: %s" % " -> ".join(
            [os.path.basename(p) for p in seen + [real]]))
    seen.append(real)

    try:
        with open(path, "rb") as handle:
            config = tomllib.load(handle)
    except OSError as exc:
        die("cannot read %s: %s" % (path, exc.strerror))
    except tomllib.TOMLDecodeError as exc:
        die("%s: %s" % (path, exc))

    version = config.pop("schema", None)
    if version is None:
        die("%s: missing required key \"schema\"" % path)
    if version != SCHEMA_VERSION:
        die("%s: schema %r is not supported, this sw understands schema %d"
            % (path, version, SCHEMA_VERSION))

    parent = config.pop("extends", None)
    validate(config, path)

    if parent is None:
        return config
    if not isinstance(parent, str):
        die("%s: extends must be a string" % path)

    resolved = load(find_parent(parent, search_dirs), search_dirs, seen)
    merge(resolved, config)
    return resolved


def validate(config, path):
    for table, entries in config.items():
        if table not in SCHEMA:
            die("%s: unknown section [%s], expected one of: %s"
                % (path, table, ", ".join(sorted(SCHEMA))))
        if not isinstance(entries, dict):
            die("%s: [%s] must be a table" % (path, table))
        for key, value in entries.items():
            if key not in SCHEMA[table]:
                die("%s: unknown key \"%s\" in [%s], expected one of: %s"
                    % (path, key, table, ", ".join(sorted(SCHEMA[table]))))
            wanted = SCHEMA[table][key]
            # bool is a subclass of int, so page_size = true must not pass
            if isinstance(value, bool) and wanted is int:
                die("%s: [%s] %s must be a number" % (path, table, key))
            if not isinstance(value, wanted):
                die("%s: [%s] %s has the wrong type" % (path, table, key))


def expander(kernel_root):
    def expand(value):
        def replace(match):
            name = match.group(1)
            if name == "kernel.root":
                return kernel_root
            if name.startswith("env."):
                variable = name[len("env."):]
                if variable not in os.environ:
                    die("%s is not set in the environment" % variable)
                return os.environ[variable]
            die("unknown expansion ${%s}" % name)

        return EXPANSION.sub(replace, value)

    return expand


def flatten(config, expand):
    """Map the schema onto the variable names build.sh consumes."""
    device = config.get("device", {})
    kernel = config.get("kernel", {})
    toolchain = config.get("toolchain", {})
    build = config.get("build", {})
    dtbo = config.get("dtbo", {})
    anykernel = config.get("anykernel", {})
    external = config.get("external_modules", {})

    def text(value):
        return expand(value) if value else ""

    def flag(value):
        return "1" if value else ""

    out_dir = text(build.get("out_dir", ""))

    # dtbo.path is documented relative to the build output directory,
    # so join it here and keep build.sh unchanged.
    dtbo_path = text(dtbo.get("path", ""))
    if dtbo_path:
        dtbo_path = os.path.join(out_dir or "out", dtbo_path)

    page_size = dtbo.get("page_size", 0)

    # "${kernel.root}/../<soc>-modules" is the normal way to reach a
    # sibling module repo, so tidy the result before it reaches make.
    modules_root = text(external.get("root", ""))
    if modules_root:
        modules_root = os.path.normpath(modules_root)

    return {
        "device_arch": text(kernel.get("arch", "")),
        "kernel_arch": text(kernel.get("defconfig_arch", "")),
        "kernel_defconfig": " ".join(expand(d) for d in
                                     kernel.get("defconfigs", [])),
        "kernel_image_name": text(kernel.get("image", "")),
        "cross_compile": text(toolchain.get("cross_compile", "")),
        "cross_compile_arm32": text(toolchain.get("cross_compile_arm32", "")),
        "use_clang": flag(toolchain.get("clang")),
        "board_platform": text(device.get("board_platform", "")),
        "build_silent": flag(build.get("silent")),
        "build_clean": flag(build.get("clean")),
        "do_modules": flag(build.get("modules")),
        "create_dist": flag(build.get("dist")),
        "out_dir": out_dir,
        "create_dtbo": flag(dtbo.get("enabled")),
        "dtbo_page_size": str(page_size) if page_size else "",
        "dtbo_arch_path": dtbo_path,
        "do_anykernel": flag(anykernel.get("enabled")),
        "anykernel_branch": text(anykernel.get("branch", "")),
        "ext_modules_root": modules_root,
        "ext_modules": " ".join(expand(p) for p in
                                external.get("paths", [])),
    }


def require(variables, config, path):
    if not variables["device_arch"]:
        die("%s: [kernel] arch is required" % path)
    if not variables["kernel_defconfig"]:
        die("%s: [kernel] defconfigs is required" % path)


def main():
    parser = argparse.ArgumentParser(
        prog="swconfig.py",
        description="Resolve a sworkflow TOML config into shell assignments")
    parser.add_argument("config", help="path to sworkflow.<device>.toml")
    parser.add_argument("--search", action="append", default=[], metavar="DIR",
                        help="directory to resolve extends against, "
                             "repeatable and tried in order")
    parser.add_argument("--kernel-root", default=os.getcwd(), metavar="DIR",
                        help="value of ${kernel.root}, defaults to cwd")
    parser.add_argument("--check", action="store_true",
                        help="validate only, print nothing")
    args = parser.parse_args()

    search = args.search or [os.path.dirname(os.path.abspath(args.config))]
    config = load(args.config, search)
    expand = expander(os.path.abspath(args.kernel_root))
    variables = flatten(config, expand)
    require(variables, config, args.config)

    if args.check:
        return

    for name, value in variables.items():
        print("%s=%s" % (name, shlex.quote(value)))
    for name, value in config.get("toolchain", {}).get("env", {}).items():
        print("export %s=%s" % (name, shlex.quote(expand(str(value)))))


if __name__ == "__main__":
    main()
