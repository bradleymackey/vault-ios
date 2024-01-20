SHELL = /bin/sh

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
