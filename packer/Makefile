#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -euc

PACKER := $(shell command -v packer 2>/dev/null)
QEMU_IMG := $(shell command -v qemu-img 2>/dev/null)

PACKER_WORK_DIR := ./
PACKER_CACHE_DIR := ./packer_cache/
PACKER_ARMHF_OUT := ./dist/armhf/pwnagotchi.img

##################################################
## "all" target
##################################################

.PHONY: all
all: build

##################################################
## "build" target
##################################################

.PHONY: build
build: build-armhf

.PHONY: build-armhf
build-armhf: $(PACKER_ARMHF_OUT)

$(PACKER_ARMHF_OUT):
	mkdir -p '$(dir $(PACKER_ARMHF_OUT))'
	'$(PACKER)' build -force -only=arm-image.armhf '$(PACKER_WORK_DIR)'
	'$(QEMU_IMG)' resize -f raw '$(PACKER_ARMHF_OUT)' 8G

##################################################
## "clean" target
##################################################

.PHONY: clean
clean:
	rm -rf '$(PACKER_ARMHF_OUT)' '$(PACKER_CACHE_DIR)'
