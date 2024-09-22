SHELL = /bin/sh

.PHONY: benchmark-release
benchmark-release:
	swift run --package-path Vault -c release KeygenSpeedtest

.PHONY: benchmark-debug
benchmark-debug:
	swift run --package-path Vault -c debug KeygenSpeedtest

.PHONY: format
format:
	swift package --package-path Vault plugin --allow-writing-to-package-directory swiftformat --quiet

.PHONY: lint
lint:
	swift package --package-path Vault plugin --allow-writing-to-package-directory swiftformat --lint --quiet && swift package --package-path Vault plugin swiftlint --quiet

.PHONY: clean
clean:
	swift package --package-path Vault clean
	rm -rf Vault/.build
