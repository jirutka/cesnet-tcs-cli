PROGNAME       = cesnet-tcs
CONFNAME       = $(PROGNAME).conf
SCRIPTS        = cesnet-tcs cesnet-tcs-fetch-issued cesnet-tcs-renew

BUILD_DIR     := .build
SCRIPT_SHELL  := /bin/sh

prefix        := /usr/local
bindir        := $(prefix)/bin
spooldir      := /var/spool
sysconfdir    := /etc

CERTS_DIR     := $(sysconfdir)/ssl/cesnet
CONF_DIR      := $(sysconfdir)/$(PROGNAME)
DAILY_DIR     := $(sysconfdir)/periodic/daily
HOURLY_DIR    := $(sysconfdir)/periodic/hourly
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

#: Install the scripts, configuration file and prepare the spool directory.
install: $(addprefix $(D)/,$(SCRIPTS)) $(D)/$(CONFNAME)
	for script in $(SCRIPTS); do \
		$(INSTALL) -m 755 -D $(D)/$$script "$(DESTDIR)$(bindir)/$$script"; \
	done
	$(INSTALL) -m 644 -D $(D)/$(CONFNAME) "$(DESTDIR)$(CONF_DIR)/$(CONFNAME)"
	$(INSTALL) -m 755 -D post-fetch.sh "$(DESTDIR)$(CONF_DIR)/post-fetch.sh"
	$(INSTALL) -d "$(DESTDIR)$(SPOOL_DIR)"
	$(INSTALL) -d "$(DESTDIR)$(CERTS_DIR)"

#: Create symlinks for cron scripts.
install-cron:
	$(INSTALL) -d "$(DESTDIR)$(HOURLY_DIR)"
	ln -s $(bindir)/cesnet-tcs-fetch-issued "$(DESTDIR)$(HOURLY_DIR)/cesnet-tcs-fetch-issued"
	$(INSTALL) -d "$(DESTDIR)$(DAILY_DIR)"
	ln -s $(bindir)/cesnet-tcs-renew "$(DESTDIR)$(DAILY_DIR)/cesnet-tcs-renew"

#: Remove the scripts, configuration file and the spool directory.
uninstall: uninstall-cron
	rm -f $(addprefix "$(DESTDIR)$(bindir)"/,$(SCRIPTS))
	rm -f "$(DESTDIR)$(CONF_DIR)/$(CONFNAME)"
	rm -f "$(DESTDIR)$(CONF_DIR)/post-fetch.sh"
	rm -f "$(DESTDIR)$(SPOOL_DIR)"/*
	rmdir "$(DESTDIR)$(SPOOL_DIR)"

#: Remove symlinks for cron scripts.
uninstall-cron:
	rm -f "$(DESTDIR)$(HOURLY_DIR)/cesnet-tcs-fetch-issued"
	rm -f "$(DESTDIR)$(DAILY_DIR)/cesnet-tcs-renew"

#: Update version in the script and README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(readonly VERSION)=.*/\1='$(VERSION)'/" $(SCRIPTS)
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
		-e 's|/etc/cesnet-tcs/|$(CONF_DIR)/|g' \
		-e 's|/etc/ssl/cesnet|$(CERTS_DIR)|g' \
		-e 's|/var/spool/cesnet-tcs|$(SPOOL_DIR)|g' \
		$< > $@

$(D):
	@mkdir -p "$(D)"

.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: help install install-cron uninstall uninstall-cron bump-version release .check-git-clean
