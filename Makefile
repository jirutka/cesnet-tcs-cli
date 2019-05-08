PROGNAME       = cesnet-tcs
CONFNAME       = $(PROGNAME).conf

prefix        := /usr/local
bindir        := $(prefix)/bin
sysconfdir    := /etc

INSTALL       := install
GIT           := git
SED           := sed


#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_LIST) \
		| while read label desc; do printf '%-20s %s\n' "$$label" "$$desc"; done

#: Install the script and configuration file.
install:
	$(INSTALL) -m 755 -D $(PROGNAME) "$(DESTDIR)$(bindir)/$(PROGNAME)"
	$(INSTALL) -m 644 -D $(CONFNAME) "$(DESTDIR)$(sysconfdir)/$(CONFNAME)"

#: Remove the script and configuration file.
uninstall:
	rm -f "$(DESTDIR)$(bindir)/$(PROGNAME)"
	rm -f "$(DESTDIR)$(sysconfdir)/$(CONFNAME)"

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


.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: help install uninstall bump-version release .check-git-clean
