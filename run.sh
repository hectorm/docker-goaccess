#!/bin/sh

set -eu
export LC_ALL=C

DOCKER_IMAGE_NAMESPACE=hectormolinero
DOCKER_IMAGE_NAME=goaccess
DOCKER_IMAGE_VERSION=latest
DOCKER_IMAGE=${DOCKER_IMAGE_NAMESPACE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}

imageExists() { [ -n "$(docker images -q "$1")" ]; }

if ! imageExists "${DOCKER_IMAGE}"; then
	>&2 printf -- '%s\n' "${DOCKER_IMAGE} image doesn't exist!"
	exit 1
fi

exec docker run -it --rm "${DOCKER_IMAGE}" "$@"
