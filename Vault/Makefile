SHELL = /bin/sh

.PHONY: benchmark-keygen
benchmark-keygen:
	swift run -c release vault-keygen-speedtest

.PHONY: format
format:
	swift package plugin --allow-writing-to-package-directory swiftlint --fix --quiet ./Sources
	swift package --allow-writing-to-package-directory format --sources=./

.PHONY: lint
lint:
	swift package plugin --allow-writing-to-package-directory swiftlint --strict --quiet ./Sources
	swift package --allow-writing-to-package-directory format --lint --sources=./

.PHONY: clean
clean:
	swift package clean
	rm -rf .build
