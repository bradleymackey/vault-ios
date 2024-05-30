SHELL = /bin/sh

.PHONY: benchmark-release
benchmark-release:
	swift run --package-path Vault -c release KeygenSpeedtest

.PHONY: benchmark-debug
benchmark-debug:
	swift run --package-path Vault -c debug KeygenSpeedtest

.PHONY: format
format:
	swift package --package-path Vault --allow-writing-to-package-directory format

.PHONY: lint
lint:
	swift package --package-path Vault --allow-writing-to-package-directory format --lint

.PHONY: clean
clean:
	swift package --package-path Vault clean
	rm -rf Vault/.build
