#!/bin/sh

set -eu
export LC_ALL=C

DOCKER_IMAGE_NAMESPACE=hectormolinero
DOCKER_IMAGE_NAME=goaccess
DOCKER_IMAGE_VERSION=latest
DOCKER_IMAGE=${DOCKER_IMAGE_NAMESPACE}/${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_VERSION}

LOG_FILE="$(readlink -f "$1")"
LOG_FORMAT="${2:-COMBINED}"

exec docker run --tty --interactive --rm \
	--mount type=bind,src="${LOG_FILE}",dst=/access.log,ro \
	"${DOCKER_IMAGE}" /access.log --log-format="${LOG_FORMAT}"
