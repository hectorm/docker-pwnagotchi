#!/bin/sh

set -eu
export LC_ALL=C

DOCKER=$(command -v docker 2>/dev/null)

IMAGE_REGISTRY=docker.io
IMAGE_NAMESPACE=hectorm
IMAGE_PROJECT=pwnagotchi
IMAGE_TAG=latest
IMAGE_NAME=${IMAGE_REGISTRY:?}/${IMAGE_NAMESPACE:?}/${IMAGE_PROJECT:?}:${IMAGE_TAG:?}
CONTAINER_NAME=${IMAGE_PROJECT:?}

imageExists() { [ -n "$("${DOCKER:?}" images -q "${1:?}")" ]; }
containerExists() { "${DOCKER:?}" ps -af name="${1:?}" --format '{{.Names}}' | grep -Fxq "${1:?}"; }
containerIsRunning() { "${DOCKER:?}" ps -f name="${1:?}" --format '{{.Names}}' | grep -Fxq "${1:?}"; }

if ! imageExists "${IMAGE_NAME:?}" && ! imageExists "${IMAGE_NAME#docker.io/}"; then
	>&2 printf '%s\n' "\"${IMAGE_NAME:?}\" image doesn't exist!"
	exit 1
fi

if containerIsRunning "${CONTAINER_NAME:?}"; then
	printf '%s\n' "Stopping \"${CONTAINER_NAME:?}\" container..."
	"${DOCKER:?}" stop "${CONTAINER_NAME:?}" >/dev/null
fi

if containerExists "${CONTAINER_NAME:?}"; then
	printf '%s\n' "Removing \"${CONTAINER_NAME:?}\" container..."
	"${DOCKER:?}" rm "${CONTAINER_NAME:?}" >/dev/null
fi

printf '%s\n' "Creating \"${CONTAINER_NAME:?}\" container..."
"${DOCKER:?}" run \
	--tty --detach \
	--name "${CONTAINER_NAME:?}" \
	--hostname "${CONTAINER_NAME:?}" \
	--restart on-failure:3 \
	--privileged --net host \
	--env PWNAGOTCHI_IFACE_MON=wlp3s0 \
	--env PWNAGOTCHI_DISPLAY_ENABLED=false \
	--env PWNAGOTCHI_PLUGIN_GRID_ENABLED=false \
	--env PWNAGOTCHI_PLUGIN_LED_ENABLED=false \
	--mount type=tmpfs,dst=/run/,tmpfs-mode=0755 \
	--mount type=tmpfs,dst=/tmp/,tmpfs-mode=1777 \
	--mount type=bind,src=/sys/fs/cgroup/,dst=/sys/fs/cgroup/,ro \
	"${IMAGE_NAME:?}" "$@" >/dev/null

printf '%s\n\n' 'Done!'
exec "${DOCKER:?}" logs -f "${CONTAINER_NAME:?}"
