=================
Project Structure
=================

Directory Layout
----------------

::

    sworkflow/
    ├── sw                    # Main executable
    ├── src/                  # Source modules
    │   ├── build.sh          # Kernel build logic
    │   ├── build_vars.sh     # Build variables
    │   ├── init.sh           # Config generation
    │   ├── help.sh           # Help command
    │   ├── version.sh        # Version command
    │   ├── sw_functions.sh   # Utility functions
    │   ├── sw_color.sh       # Terminal colors
    │   └── sw_package.sh     # Packaging (WIP)
    ├── configs/              # Device configurations
    │   ├── base/             # Architecture and toolchain profiles
    │   └── soc/              # SoC profiles
    ├── utils/                # Python utilities
    │   ├── swconfig.py       # TOML config loader
    │   └── mkdtboimg.py      # DTBO image creator
    ├── man/                  # Man pages
    │   └── sw.1              # Main man page
    ├── debian/               # Debian packaging
    ├── docs/                 # Sphinx documentation
    ├── tests/                # Test scripts
    ├── Makefile              # Build system
    ├── setup.sh              # Legacy installer
    └── README.md             # Project readme

Source Modules
--------------

**sw**
    Main entry point. Handles command routing and path detection.

**src/build.sh**
    Core kernel build logic. Handles:

    - Config loading and validation
    - Cross-compiler setup
    - Kernel compilation with make
    - Module installation
    - DTBO generation
    - AnyKernel3 packaging

**src/init.sh**
    Interactive configuration generator. Creates device-specific
    config files with user input.

**src/sw_functions.sh**
    Shared utility functions:

    - ``sw_config_search_dirs()`` - Fill the config search path
    - ``sw_find_config()`` - Locate a device's config
    - ``sw_load_config()`` - Load a config into the shell
    - ``is_kernel_root()`` - Check if directory is a kernel tree
    - ``is_kernel_image_present()`` - Check for compiled kernel
    - ``log_info()``, ``log_error()`` - Logging functions

**utils/swconfig.py**
    Resolves a TOML device config: follows ``extends``, checks it against
    the schema, expands ``${kernel.root}`` and ``${env.NAME}``, and prints
    the result as shell assignments. Config files are parsed as data and
    never sourced, so they cannot run code.

**src/sw_color.sh**
    Terminal color definitions for output formatting.

Installation Paths
------------------

**System Installation** (``sudo make install``)::

    /usr/bin/sw                    # Executable
    /usr/share/sworkflow/src/      # Source modules
    /usr/share/sworkflow/utils/    # Python utilities
    /etc/sworkflow/                # Device configs
    /etc/sworkflow/base/           # Architecture and toolchain profiles
    /etc/sworkflow/soc/            # SoC profiles
    /usr/share/man/man1/sw.1       # Man page

**User Installation** (``make install``)::

    ~/.local/bin/sw                # Executable
    ~/.local/sw/src/               # Source modules
    ~/.local/sw/utils/             # Python utilities
    ~/.local/sw/configs/           # Device configs
    ~/.local/sw/configs/base/      # Architecture and toolchain profiles
    ~/.local/sw/configs/soc/       # SoC profiles

Configuration Files
-------------------

Device configurations are shell scripts named ``sworkflow.<device>.config``.

They are searched in order:

1. ``/etc/sworkflow/`` (system)
2. ``~/.local/sw/configs/`` (user)
3. Current directory
4. ``./configs/`` subdirectory

See ``configs/sworkflow_template.config`` for available variables.
