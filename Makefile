#!/usr/bin/make -f

SHELL := /bin/sh
.SHELLFLAGS := -eu -c

DOCKER := $(shell command -v docker 2>/dev/null)
GIT := $(shell command -v git 2>/dev/null)
M4 := $(shell command -v m4 2>/dev/null)

DISTDIR := ./dist
VERSION_FILE = ./VERSION
DOCKERFILE_TEMPLATE := ./Dockerfile.m4

IMAGE_REGISTRY := docker.io
IMAGE_NAMESPACE := hectormolinero
IMAGE_PROJECT := pwnagotchi
IMAGE_NAME := $(IMAGE_REGISTRY)/$(IMAGE_NAMESPACE)/$(IMAGE_PROJECT)

IMAGE_VERSION := v0
ifneq ($(wildcard $(VERSION_FILE)),)
	IMAGE_VERSION := $(shell cat '$(VERSION_FILE)')
endif

IMAGE_BUILD_OPTS :=

IMAGE_NATIVE_DOCKERFILE := $(DISTDIR)/Dockerfile
IMAGE_NATIVE_TARBALL := $(DISTDIR)/$(IMAGE_PROJECT).txz

IMAGE_GENERIC_AMD64_DOCKERFILE := $(DISTDIR)/Dockerfile.generic-amd64
IMAGE_GENERIC_AMD64_TARBALL := $(DISTDIR)/$(IMAGE_PROJECT).generic-amd64.txz

IMAGE_RASPBIAN_ARM64V8_DOCKERFILE := $(DISTDIR)/Dockerfile.raspbian-arm64v8
IMAGE_RASPBIAN_ARM64V8_TARBALL := $(DISTDIR)/$(IMAGE_PROJECT).raspbian-arm64v8.txz

IMAGE_RASPBIAN_ARM32V7_DOCKERFILE := $(DISTDIR)/Dockerfile.raspbian-arm32v7
IMAGE_RASPBIAN_ARM32V7_TARBALL := $(DISTDIR)/$(IMAGE_PROJECT).raspbian-arm32v7.txz

IMAGE_RASPBIAN_ARM32V6_DOCKERFILE := $(DISTDIR)/Dockerfile.raspbian-arm32v6
IMAGE_RASPBIAN_ARM32V6_TARBALL := $(DISTDIR)/$(IMAGE_PROJECT).raspbian-arm32v6.txz

##################################################
## "all" target
##################################################

.PHONY: all
all: save-native-image

##################################################
## "build-*" targets
##################################################

.PHONY: build-native-image
build-native-image: $(IMAGE_NATIVE_DOCKERFILE)

$(IMAGE_NATIVE_DOCKERFILE): $(DOCKERFILE_TEMPLATE)
	mkdir -p '$(DISTDIR)'
	'$(M4)' \
		--prefix-builtins \
		-D DEBIAN_IMAGE_NAME=docker.io/debian -D DEBIAN_IMAGE_TAG=buster \
		'$(DOCKERFILE_TEMPLATE)' | cat --squeeze-blank > '$@'
	'$(DOCKER)' build $(IMAGE_BUILD_OPTS) \
		--tag '$(IMAGE_NAME):$(IMAGE_VERSION)' \
		--tag '$(IMAGE_NAME):latest' \
		--file '$@' ./

.PHONY: build-cross-images
build-cross-images: build-generic-amd64-image build-raspbian-arm64v8-image build-raspbian-arm32v7-image build-raspbian-arm32v6-image

.PHONY: build-generic-amd64-image
build-generic-amd64-image: $(IMAGE_GENERIC_AMD64_DOCKERFILE)

$(IMAGE_GENERIC_AMD64_DOCKERFILE): $(DOCKERFILE_TEMPLATE)
	mkdir -p '$(DISTDIR)'
	'$(M4)' \
		--prefix-builtins \
		-D DEBIAN_IMAGE_NAME=docker.io/amd64/debian -D DEBIAN_IMAGE_TAG=buster \
		-D CROSS_QEMU=/usr/bin/qemu-x86_64-static \
		'$(DOCKERFILE_TEMPLATE)' | cat --squeeze-blank > '$@'
	'$(DOCKER)' build $(IMAGE_BUILD_OPTS) \
		--tag '$(IMAGE_NAME):$(IMAGE_VERSION)-generic-amd64' \
		--tag '$(IMAGE_NAME):latest-generic-amd64' \
		--file '$@' ./

.PHONY: build-raspbian-arm64v8-image
build-raspbian-arm64v8-image: $(IMAGE_RASPBIAN_ARM64V8_DOCKERFILE)

$(IMAGE_RASPBIAN_ARM64V8_DOCKERFILE): $(DOCKERFILE_TEMPLATE)
	mkdir -p '$(DISTDIR)'
	'$(M4)' \
		--prefix-builtins \
		-D DEBIAN_IMAGE_NAME=docker.io/balenalib/rpi-raspbian -D DEBIAN_IMAGE_TAG=buster \
		-D CROSS_QEMU=/usr/bin/qemu-arm-static \
		'$(DOCKERFILE_TEMPLATE)' | cat --squeeze-blank > '$@'
	'$(DOCKER)' build $(IMAGE_BUILD_OPTS) \
		--tag '$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm64v8' \
		--tag '$(IMAGE_NAME):latest-raspbian-arm64v8' \
		--file '$@' ./

.PHONY: build-raspbian-arm32v7-image
build-raspbian-arm32v7-image: $(IMAGE_RASPBIAN_ARM32V7_DOCKERFILE)

$(IMAGE_RASPBIAN_ARM32V7_DOCKERFILE): $(DOCKERFILE_TEMPLATE)
	mkdir -p '$(DISTDIR)'
	'$(M4)' \
		--prefix-builtins \
		-D DEBIAN_IMAGE_NAME=docker.io/balenalib/rpi-raspbian -D DEBIAN_IMAGE_TAG=buster \
		-D CROSS_QEMU=/usr/bin/qemu-arm-static \
		'$(DOCKERFILE_TEMPLATE)' | cat --squeeze-blank > '$@'
	'$(DOCKER)' build $(IMAGE_BUILD_OPTS) \
		--tag '$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v7' \
		--tag '$(IMAGE_NAME):latest-raspbian-arm32v7' \
		--file '$@' ./

.PHONY: build-raspbian-arm32v6-image
build-raspbian-arm32v6-image: $(IMAGE_RASPBIAN_ARM32V6_DOCKERFILE)

$(IMAGE_RASPBIAN_ARM32V6_DOCKERFILE): $(DOCKERFILE_TEMPLATE)
	mkdir -p '$(DISTDIR)'
	'$(M4)' \
		--prefix-builtins \
		-D DEBIAN_IMAGE_NAME=docker.io/balenalib/rpi-raspbian -D DEBIAN_IMAGE_TAG=buster \
		-D CROSS_QEMU=/usr/bin/qemu-arm-static \
		'$(DOCKERFILE_TEMPLATE)' | cat --squeeze-blank > '$@'
	'$(DOCKER)' build $(IMAGE_BUILD_OPTS) \
		--tag '$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v6' \
		--tag '$(IMAGE_NAME):latest-raspbian-arm32v6' \
		--file '$@' ./

##################################################
## "save-*" targets
##################################################

define save_image
	'$(DOCKER)' save '$(1)' | xz -T0 > '$(2)'
endef

.PHONY: save-native-image
save-native-image: $(IMAGE_NATIVE_TARBALL)

$(IMAGE_NATIVE_TARBALL): $(IMAGE_NATIVE_DOCKERFILE)
	$(call save_image,$(IMAGE_NAME):$(IMAGE_VERSION),$@)

.PHONY: save-cross-images
save-cross-images: save-generic-amd64-image save-raspbian-arm64v8-image save-raspbian-arm32v7-image save-raspbian-arm32v6-image

.PHONY: save-generic-amd64-image
save-generic-amd64-image: $(IMAGE_GENERIC_AMD64_TARBALL)

$(IMAGE_GENERIC_AMD64_TARBALL): $(IMAGE_GENERIC_AMD64_DOCKERFILE)
	$(call save_image,$(IMAGE_NAME):$(IMAGE_VERSION)-generic-amd64,$@)

.PHONY: save-raspbian-arm64v8-image
save-raspbian-arm64v8-image: $(IMAGE_RASPBIAN_ARM64V8_TARBALL)

$(IMAGE_RASPBIAN_ARM64V8_TARBALL): $(IMAGE_RASPBIAN_ARM64V8_DOCKERFILE)
	$(call save_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm64v8,$@)

.PHONY: save-raspbian-arm32v7-image
save-raspbian-arm32v7-image: $(IMAGE_RASPBIAN_ARM32V7_TARBALL)

$(IMAGE_RASPBIAN_ARM32V7_TARBALL): $(IMAGE_RASPBIAN_ARM32V7_DOCKERFILE)
	$(call save_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v7,$@)

.PHONY: save-raspbian-arm32v6-image
save-raspbian-arm32v6-image: $(IMAGE_RASPBIAN_ARM32V6_TARBALL)

$(IMAGE_RASPBIAN_ARM32V6_TARBALL): $(IMAGE_RASPBIAN_ARM32V6_DOCKERFILE)
	$(call save_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v6,$@)

##################################################
## "load-*" targets
##################################################

define load_image
	'$(DOCKER)' load -i '$(1)'
endef

define tag_image
	'$(DOCKER)' tag '$(1)' '$(2)'
endef

.PHONY: load-native-image
load-native-image:
	$(call load_image,$(IMAGE_NATIVE_TARBALL))
	$(call tag_image,$(IMAGE_NAME):$(IMAGE_VERSION),$(IMAGE_NAME):latest)

.PHONY: load-cross-images
load-cross-images: load-generic-amd64-image load-raspbian-arm64v8-image load-raspbian-arm32v7-image load-raspbian-arm32v6-image

.PHONY: load-generic-amd64-image
load-generic-amd64-image:
	$(call load_image,$(IMAGE_GENERIC_AMD64_TARBALL))
	$(call tag_image,$(IMAGE_NAME):$(IMAGE_VERSION)-generic-amd64,$(IMAGE_NAME):latest-generic-amd64)

.PHONY: load-raspbian-arm64v8-image
load-raspbian-arm64v8-image:
	$(call load_image,$(IMAGE_RASPBIAN_ARM64V8_TARBALL))
	$(call tag_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm64v8,$(IMAGE_NAME):latest-raspbian-arm64v8)

.PHONY: load-raspbian-arm32v7-image
load-raspbian-arm32v7-image:
	$(call load_image,$(IMAGE_RASPBIAN_ARM32V7_TARBALL))
	$(call tag_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v7,$(IMAGE_NAME):latest-raspbian-arm32v7)

.PHONY: load-raspbian-arm32v6-image
load-raspbian-arm32v6-image:
	$(call load_image,$(IMAGE_RASPBIAN_ARM32V6_TARBALL))
	$(call tag_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v6,$(IMAGE_NAME):latest-raspbian-arm32v6)

##################################################
## "push-*" targets
##################################################

define push_image
	'$(DOCKER)' push '$(1)'
endef

define push_cross_manifest
	'$(DOCKER)' manifest create --amend '$(1)' '$(2)-generic-amd64' '$(2)-raspbian-arm64v8' '$(2)-raspbian-arm32v7' '$(2)-raspbian-arm32v6'
	'$(DOCKER)' manifest annotate '$(1)' '$(2)-generic-amd64' --os linux --arch amd64
	'$(DOCKER)' manifest annotate '$(1)' '$(2)-raspbian-arm64v8' --os linux --arch arm64 --variant v8
	'$(DOCKER)' manifest annotate '$(1)' '$(2)-raspbian-arm32v7' --os linux --arch arm --variant v7
	'$(DOCKER)' manifest annotate '$(1)' '$(2)-raspbian-arm32v6' --os linux --arch arm --variant v6
	'$(DOCKER)' manifest push --purge '$(1)'
endef

.PHONY: push-native-image
push-native-image:
	@printf '%s\n' 'Unimplemented'

.PHONY: push-cross-images
push-cross-images: push-generic-amd64-image push-raspbian-arm64v8-image push-raspbian-arm32v7-image push-raspbian-arm32v6-image

.PHONY: push-generic-amd64-image
push-generic-amd64-image:
	$(call push_image,$(IMAGE_NAME):$(IMAGE_VERSION)-generic-amd64)
	$(call push_image,$(IMAGE_NAME):latest-generic-amd64)

.PHONY: push-raspbian-arm64v8-image
push-raspbian-arm64v8-image:
	$(call push_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm64v8)
	$(call push_image,$(IMAGE_NAME):latest-raspbian-arm64v8)

.PHONY: push-raspbian-arm32v7-image
push-raspbian-arm32v7-image:
	$(call push_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v7)
	$(call push_image,$(IMAGE_NAME):latest-raspbian-arm32v7)

.PHONY: push-raspbian-arm32v6-image
push-raspbian-arm32v6-image:
	$(call push_image,$(IMAGE_NAME):$(IMAGE_VERSION)-raspbian-arm32v6)
	$(call push_image,$(IMAGE_NAME):latest-raspbian-arm32v6)

push-cross-manifest:
	$(call push_cross_manifest,$(IMAGE_NAME):$(IMAGE_VERSION),$(IMAGE_NAME):$(IMAGE_VERSION))
	$(call push_cross_manifest,$(IMAGE_NAME):latest,$(IMAGE_NAME):latest)

##################################################
## "binfmt-*" targets
##################################################

.PHONY: binfmt-register
binfmt-register:
	'$(DOCKER)' run --rm --privileged docker.io/hectormolinero/qemu-user-static:latest

.PHONY: binfmt-reset
binfmt-reset:
	'$(DOCKER)' run --rm --privileged docker.io/hectormolinero/qemu-user-static:latest --reset

##################################################
## "version" target
##################################################

.PHONY: version
version:
	@if printf -- '%s' '$(IMAGE_VERSION)' | grep -q '^v[0-9]\{1,\}$$'; then \
		NEW_IMAGE_VERSION=$$(awk -v 'v=$(IMAGE_VERSION)' 'BEGIN {printf "v%.0f", substr(v,2)+1}'); \
		printf -- '%s\n' "$${NEW_IMAGE_VERSION:?}" > '$(VERSION_FILE)'; \
		'$(GIT)' add '$(VERSION_FILE)'; '$(GIT)' commit -m "$${NEW_IMAGE_VERSION:?}"; \
		'$(GIT)' tag -a "$${NEW_IMAGE_VERSION:?}" -m "$${NEW_IMAGE_VERSION:?}"; \
	else \
		>&2 printf -- 'Malformed version string: %s\n' '$(IMAGE_VERSION)'; \
		exit 1; \
	fi

##################################################
## "clean" target
##################################################

.PHONY: clean
clean:
	rm -f '$(IMAGE_NATIVE_DOCKERFILE)' '$(IMAGE_GENERIC_AMD64_DOCKERFILE)' '$(IMAGE_RASPBIAN_ARM64V8_DOCKERFILE)' '$(IMAGE_RASPBIAN_ARM32V7_DOCKERFILE)' '$(IMAGE_RASPBIAN_ARM32V6_DOCKERFILE)'
	rm -f '$(IMAGE_NATIVE_TARBALL)' '$(IMAGE_GENERIC_AMD64_TARBALL)' '$(IMAGE_RASPBIAN_ARM64V8_TARBALL)' '$(IMAGE_RASPBIAN_ARM32V7_TARBALL)' '$(IMAGE_RASPBIAN_ARM32V6_TARBALL)'
	if [ -d '$(DISTDIR)' ] && [ -z "$$(ls -A '$(DISTDIR)')" ]; then rmdir '$(DISTDIR)'; fi
