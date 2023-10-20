SHELL = /bin/sh

.PHONY: format
format:
	swift package --allow-writing-to-package-directory format

.PHONY: lint
lint:
	swift package --allow-writing-to-package-directory format --lint

.PHONY: clean
clean:
	swift package clean
	rm -rf .build
