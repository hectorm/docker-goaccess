#!/bin/sh

set -eu
export LC_ALL=C

DOCKER=$(command -v docker 2>/dev/null)

IMAGE_REGISTRY=docker.io
IMAGE_NAMESPACE=hectormolinero
IMAGE_PROJECT=goaccess
IMAGE_TAG=latest
IMAGE_NAME=${IMAGE_REGISTRY:?}/${IMAGE_NAMESPACE:?}/${IMAGE_PROJECT:?}:${IMAGE_TAG:?}

LOG_FILE=$(readlink -f "$1")
LOG_FORMAT=${2:-COMBINED:?}

exec "${DOCKER:?}" run --rm \
	--mount type=bind,src="${LOG_FILE:?}",dst=/access.log,ro \
	"${IMAGE_NAME:?}" /access.log --log-format="${LOG_FORMAT:?}"
