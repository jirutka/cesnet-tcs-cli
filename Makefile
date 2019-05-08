PROGNAME       = cesnet-tcs
CONFNAME       = $(PROGNAME).conf

BUILD_DIR     := .build
SCRIPT_SHELL  := /bin/sh

prefix        := /usr/local
bindir        := $(prefix)/bin
spooldir      := /var/spool
sysconfdir    := /etc

CERTS_DIR     := $(sysconfdir)/ssl/cesnet
CONF_DIR      := $(sysconfdir)/$(PROGNAME)
SPOOL_DIR     := $(spooldir)/$(PROGNAME)

INSTALL       := install
GIT           := git
SED           := sed

D              = $(BUILD_DIR)


#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_LIST) \
		| while read label desc; do printf '%-20s %s\n' "$$label" "$$desc"; done

#: Install the script, configuration file and prepare the spool directory.
install: $(D)/$(PROGNAME) $(D)/$(CONFNAME)
	$(INSTALL) -m 755 -D $(D)/$(PROGNAME) "$(DESTDIR)$(bindir)/$(PROGNAME)"
	$(INSTALL) -m 644 -D $(D)/$(CONFNAME) "$(DESTDIR)$(CONF_DIR)/$(CONFNAME)"
	$(INSTALL) -d "$(DESTDIR)$(SPOOL_DIR)"
	$(INSTALL) -d "$(DESTDIR)$(CERTS_DIR)"

#: Remove the script, configuration file and the spool directory.
uninstall:
	rm -f "$(DESTDIR)$(bindir)/$(PROGNAME)"
	rm -f "$(DESTDIR)$(CONF_DIR)/$(CONFNAME)"
	rm -f "$(DESTDIR)$(SPOOL_DIR)"/*
	rmdir "$(DESTDIR)$(SPOOL_DIR)"

#: Update version in the script and README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" $(PROGNAME)
	$(SED) -E -i "s/^(:version:).*/\1 $(VERSION)/" README.adoc

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version
	test -n "$(VERSION)"  # $$VERSION
	$(GIT) add .
	$(GIT) commit -m "Release version $(VERSION)"
	$(GIT) tag v$(VERSION) -m v$(VERSION)



$(D)/%: % | $(D)
	@$(SED) \
		-e 's|^#!/bin/sh|#!$(SCRIPT_SHELL)|' \
		-e 's|/etc/cesnet-tcs/cesnet-tcs\.conf|$(CONF_DIR)/$(CONFNAME)|g' \
		-e 's|/var/spool/cesnet-tcs|$(SPOOL_DIR)|g' \
		-e 's|/etc/ssl/cesnet|$(CERTS_DIR)|g' \
		$< > $@

$(D):
	@mkdir -p "$(D)"

.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: help install uninstall bump-version release .check-git-clean
