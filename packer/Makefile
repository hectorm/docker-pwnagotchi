#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -eu -c

PACKER := $(shell command -v packer 2>/dev/null)

PACKER_WORK_DIR := ./
PACKER_CACHE_DIR := ./packer_cache/
PACKER_IMG := ./dist/pwnagotchi.img

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
	'$(PACKER)' build '$(PACKER_WORK_DIR)'

##################################################
## "clean" target
##################################################

.PHONY: clean
clean:
	rm -rf '$(PACKER_IMG)' '$(PACKER_CACHE_DIR)'
