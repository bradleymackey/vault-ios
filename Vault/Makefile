SHELL = /bin/sh

.PHONY: benchmark-keygen
benchmark-keygen:
	swift run -c release vault-keygen-speedtest

.PHONY: format
format:
	swift package --allow-writing-to-package-directory format --sources=./

.PHONY: lint
lint:
	swift package --allow-writing-to-package-directory format --lint --sources=./

.PHONY: clean
clean:
	swift package clean
	rm -rf .build
