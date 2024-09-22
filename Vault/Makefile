SHELL = /bin/sh

.PHONY: benchmark-release
benchmark-release:
	swift run -c release KeygenSpeedtest

.PHONY: benchmark-debug
benchmark-debug:
	swift run-c debug KeygenSpeedtest

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
