SHELL := /usr/bin/env bash

CONFIG_INPUT ?= config/install.selection.env
CONFIG_OUTPUT ?= config/install.generated.env

.PHONY: build-install-config install

build-install-config:
	./scripts/build-install-config.sh --selection-file "$(CONFIG_INPUT)" --output "$(CONFIG_OUTPUT)"

install: build-install-config
	./install.sh
