#!/bin/bash +xe

docker build \
  --tag local/terraform-azure-docker \
  --build-arg IMAGE_VERSION=dev \
  --build-arg IMAGE_CREATION_DATETIME=$(date --rfc-3339=seconds | sed 's/ /T/') \
  --build-arg IMAGE_GIT_SHA1=sha1 \
  .