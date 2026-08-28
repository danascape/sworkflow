#
# SPDX-FileCopyrightText: 2019 Saalim Quadri <danascape@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Package metadata
PACKAGE = sworkflow
VERSION = 2.0

# System installation directories
PREFIX ?= /usr
DESTDIR ?=
BINDIR = $(PREFIX)/bin
DATADIR = $(PREFIX)/share/$(PACKAGE)
SYSCONFDIR = /etc/$(PACKAGE)
MANDIR = $(PREFIX)/share/man

# User installation directories
USER_BINDIR = $(HOME)/.local/bin
USER_DATADIR = $(HOME)/.local/sw

# Source files
SRCDIR = src
UTILSDIR = utils
CONFIGDIR = configs

# Config subdirectories holding the profiles devices inherit via
# `extends`. They have to ship, or a converted config cannot resolve.
PROFILEDIRS = base soc

# Main entry point

install:
ifeq ($(shell id -u),0)
	@echo "Root detected, installing system-wide to $(PREFIX)..."
	@$(MAKE) --no-print-directory _install-system
else
	@echo "Installing for user $(USER) to ~/.local/..."
	@$(MAKE) --no-print-directory _install-user
endif

uninstall:
ifeq ($(shell id -u),0)
	@echo "Root detected, removing system installation..."
	@$(MAKE) --no-print-directory _uninstall-system
else
	@echo "Removing user installation..."
	@$(MAKE) --no-print-directory _uninstall-user
endif

# System installation

_install-system: _install-system-bin _install-system-src _install-system-utils _install-system-configs _install-system-man
	@echo "System installation complete!"

_install-system-bin:
	install -d $(DESTDIR)$(BINDIR)
	install -m 755 sw $(DESTDIR)$(BINDIR)/sw

_install-system-src:
	install -d $(DESTDIR)$(DATADIR)/$(SRCDIR)
	install -m 644 $(SRCDIR)/*.sh $(DESTDIR)$(DATADIR)/$(SRCDIR)/

_install-system-utils:
	install -d $(DESTDIR)$(DATADIR)/$(UTILSDIR)
	install -m 644 $(UTILSDIR)/*.py $(DESTDIR)$(DATADIR)/$(UTILSDIR)/

_install-system-configs:
	install -d $(DESTDIR)$(SYSCONFDIR)
	install -m 644 $(CONFIGDIR)/*.config $(CONFIGDIR)/*.toml $(DESTDIR)$(SYSCONFDIR)/
	for dir in $(PROFILEDIRS); do \
		install -d $(DESTDIR)$(SYSCONFDIR)/$$dir; \
		install -m 644 $(CONFIGDIR)/$$dir/*.toml $(DESTDIR)$(SYSCONFDIR)/$$dir/; \
	done

_install-system-man:
	install -d $(DESTDIR)$(MANDIR)/man1
	install -m 644 man/sw.1 $(DESTDIR)$(MANDIR)/man1/

_uninstall-system:
	rm -f $(DESTDIR)$(BINDIR)/sw
	rm -rf $(DESTDIR)$(DATADIR)
	rm -rf $(DESTDIR)$(SYSCONFDIR)
	rm -f $(DESTDIR)$(MANDIR)/man1/sw.1
	@echo "System uninstallation complete!"

# User installation

_install-user:
	install -d $(USER_BINDIR)
	install -d $(USER_DATADIR)/$(SRCDIR)
	install -d $(USER_DATADIR)/$(UTILSDIR)
	install -d $(USER_DATADIR)/$(CONFIGDIR)
	install -m 755 sw $(USER_BINDIR)/sw
	install -m 644 $(SRCDIR)/*.sh $(USER_DATADIR)/$(SRCDIR)/
	install -m 644 $(UTILSDIR)/*.py $(USER_DATADIR)/$(UTILSDIR)/
	install -m 644 $(CONFIGDIR)/*.config $(CONFIGDIR)/*.toml $(USER_DATADIR)/$(CONFIGDIR)/
	for dir in $(PROFILEDIRS); do \
		install -d $(USER_DATADIR)/$(CONFIGDIR)/$$dir; \
		install -m 644 $(CONFIGDIR)/$$dir/*.toml $(USER_DATADIR)/$(CONFIGDIR)/$$dir/; \
	done
	@echo ""
	@echo "Installation complete!"
	@echo "Make sure $(USER_BINDIR) is in your PATH."
	@echo "Add this to your ~/.bashrc if needed:"
	@echo '  export PATH="$$HOME/.local/bin:$$PATH"'

_uninstall-user:
	rm -f $(USER_BINDIR)/sw
	rm -rf $(USER_DATADIR)
	@echo "User uninstallation complete."

# Development targets

format:
	while read -r script; do shfmt -ln=bash -fn -ci -sr -w $$script; done < tests/files

tests:
	@./tests/run_tests.sh

docs:
	$(MAKE) -C docs html

docs-clean:
	$(MAKE) -C docs clean

# Distribution targets

dist:
	mkdir -p $(PACKAGE)-$(VERSION)
	cp -r sw $(SRCDIR) $(UTILSDIR) $(CONFIGDIR) man Makefile README.md LICENSE setup.sh $(PACKAGE)-$(VERSION)/
	tar -czf $(PACKAGE)-$(VERSION).tar.gz $(PACKAGE)-$(VERSION)
	rm -rf $(PACKAGE)-$(VERSION)

clean:
	rm -rf $(PACKAGE)-$(VERSION) $(PACKAGE)-$(VERSION).tar.gz

# Help

help:
	@echo "sworkflow Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make install       Install for current user (~/.local/)"
	@echo "  sudo make install  Install system-wide (/usr/)"
	@echo ""
	@echo "  make uninstall     Remove user installation"
	@echo "  sudo make uninstall Remove system installation"
	@echo ""
	@echo "Development:"
	@echo "  make tests          Run all tests"
	@echo "  make format         Format scripts with shfmt"
	@echo "  make docs           Build documentation"
	@echo "  make docs-clean     Clean documentation build"
	@echo ""
	@echo "Distribution:"
	@echo "  make dist           Create source tarball"
	@echo "  make clean          Remove build artifacts"

.PHONY: install uninstall
.PHONY: _install-system _install-system-bin _install-system-src _install-system-utils _install-system-configs _install-system-man
.PHONY: _uninstall-system _install-user _uninstall-user
.PHONY: format tests docs docs-clean
.PHONY: dist clean help
