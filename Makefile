SHELL = /bin/sh

SWIFTFORMAT := $(shell command -v swiftformat 2>/dev/null)
SWIFTLINT := $(shell command -v swiftlint 2>/dev/null)

.PHONY: format lint precommit

precommit: format lint

format:
ifndef SWIFTFORMAT
	$(error "swiftformat not found; install with `brew install swiftformat`")
endif
	$(SWIFTFORMAT) .

lint:
ifndef SWIFTLINT
	$(error "swiftlint not found; install with `brew install swiftlint`")
endif
	$(SWIFTLINT) lint --quiet --strict .

