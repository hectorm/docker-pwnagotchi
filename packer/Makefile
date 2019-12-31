#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -eu -c

PACKER := $(shell command -v packer 2>/dev/null)

PACKER_CACHE_DIR := ./packer_cache/
PACKER_TEMPLATE := ./raspbian.json
PACKER_IMG := ./raspbian.img

##################################################
## "all" target
##################################################

.PHONY: all
all: build

##################################################
## "build" target
##################################################

.PHONY: build
build: $(PACKER_IMG)

$(PACKER_IMG):
	'$(PACKER)' build '$(PACKER_TEMPLATE)'

##################################################
## "clean" target
##################################################

.PHONY: clean
clean:
	rm -rf '$(PACKER_IMG)' '$(PACKER_CACHE_DIR)'
