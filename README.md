# sworkflow

Streamlined Linux Kernel Compilation Tool

sworkflow (sw) is an automated kernel compilation tool designed to streamline the process of compiling the Linux kernel and significantly reduce the overhead involved in setting up the development environment.

## Features

- Device-specific build configurations
- Cross-compiler management for ARM64/ARM32/x86
- Clang/LLVM build support
- DTBO image generation
- AnyKernel3 packaging integration
- Interactive config generation

## Installation

### From Debian Package (Recommended)

Download the latest `.deb` from [Releases](https://github.com/sworkflow-project/sworkflow/releases):

```bash
sudo dpkg -i sworkflow_*.deb
sudo apt-get install -f  # Install dependencies if needed
```

### From Source (User Install)

Installs to `~/.local/` - no root required:

```bash
git clone https://github.com/sworkflow-project/sworkflow.git
cd sworkflow
make install
```

Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### From Source (System-wide)

Installs to `/usr/`:

```bash
git clone https://github.com/sworkflow-project/sworkflow.git
cd sworkflow
sudo make install
```

### Uninstall

```bash
make uninstall        # Remove user installation
sudo make uninstall   # Remove system installation
```

## Dependencies

**Required:**
- bash (>= 4.0)
- python3 (>= 3.11, or `python3-tomli` on older releases — needed to read configs)
- git
- make

**Recommended (for kernel building):**
- build-essential
- bc, flex, bison
- libssl-dev, libelf-dev

**Optional:**
- clang (for LLVM builds)
- device-tree-compiler (for DTBO)

## Usage

```bash
sw <command> [device]
```

### Commands

| Command | Description |
|---------|-------------|
| `sw build <device>` | Build kernel for specified device |
| `sw doctor [device]` | Show available configs and current settings |
| `sw init` | Generate new device configuration |
| `sw help` | Display help message |
| `sw version` | Display version |

### Examples

Build kernel for a device:

```bash
cd /path/to/kernel-source
sw build mainline
```

Generate a new device config:

```bash
sw init
```

### Man Page

After installation, view the full manual:

```bash
man sw
```

## Configuration

Device configurations are TOML files named `sworkflow.<device>.toml`. They are
parsed as data and never executed, so a config file cannot run code.

**Search order:**
1. Current directory
2. `/etc/sworkflow/` (system installation) or `~/.local/sw/configs/` (user installation)
3. `./configs/` subdirectory

Within a directory a `.toml` config takes precedence over a legacy
`.config` shell file of the same name. Shell configs are still read for
compatibility but are deprecated, and `sw init` only writes TOML.

### Inheritance

A config inherits from one profile with `extends`, so a device only states
what makes it different. Profiles live in `base/` and `soc/` of a config
directory.

```toml
schema = 1
extends = "soc/lito"

[device]
name = "gauguin"
vendor = "xiaomi"

[kernel]
defconfigs = ["vendor/lito-perf_defconfig", "vendor/xiaomi/gauguin.config"]
```

Tables merge key by key and lists concatenate with the parent's entries
first, so a child adds to a profile's defconfigs or modules rather than
restating them.

### Sections

| Section | Keys |
|---------|------|
| *(top level)* | `schema` (required), `extends` |
| `[device]` | `name`, `vendor`, `aliases`, `board_platform` |
| `[kernel]` | `arch`, `defconfig_arch`, `defconfigs`, `image` |
| `[toolchain]` | `cross_compile`, `cross_compile_arm32`, `clang`, `env` |
| `[build]` | `modules`, `dist`, `clean`, `silent`, `out_dir` |
| `[dtbo]` | `enabled`, `page_size`, `path` |
| `[anykernel]` | `enabled`, `branch` |
| `[external_modules]` | `root`, `paths` |
| `[meta]` | `maintainer`, `tested_tree` |

`kernel.arch` and `kernel.defconfigs` are required. An unknown section, an
unknown key, or a value of the wrong type is an error rather than something
quietly ignored.

String values may contain `${kernel.root}` (the kernel tree being built) and
`${env.NAME}`. Expansion substitutes known names only and never invokes a
shell.

See `configs/sworkflow_template.toml` for every key with its default.

## Building Debian Package

```bash
sudo apt-get install devscripts debhelper shellcheck
dpkg-buildpackage -us -uc -b
```

The package will be created in the parent directory.

## Development

```bash
make tests          # Run all tests
make format         # Format scripts
make docs           # Build documentation
make docs-clean     # Clean documentation build
make help           # Show all targets
```

## Project Structure

```
sworkflow/
├── sw                 # Main executable
├── src/               # Source modules
├── configs/           # Device configurations
├── utils/             # Python utilities (mkdtboimg.py)
├── man/               # Man pages
├── docs/              # Sphinx documentation
├── debian/            # Debian packaging
├── tests/             # Test scripts
└── Makefile           # Build system
```

## License

GPL-3.0-or-later

Copyright (c) 2019 Saalim Quadri

## Contributing

Contributions are welcome! Please check [issues](https://github.com/sworkflow-project/issues/issues) for a good starting point.

## Links

- [Documentation](https://github.com/sworkflow-project/sworkflow/docs)
- [Issues](https://github.com/sworkflow-project/issues/issues)
- [Releases](https://github.com/sworkflow-project/sworkflow/releases)
