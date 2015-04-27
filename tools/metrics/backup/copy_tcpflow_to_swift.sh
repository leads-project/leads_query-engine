#!/bin/bash
# Copy any measurements files (to share or for a backup)

set -o nounset
set -o errexit
set -o pipefail

set +x

BASE_DIR_WITH_MEASUREMENT="/home/ubuntu/metrics/tcpflow"
MEASUREMENT_CONTAINER="experiments"
HOSTNAME=$(hostname)

MEASUREMENT_FILES_MTIME=${MEASUREMENT_FILES_MTIME:--1}
MEASUREMENT_MODIFIED_IN_LAST="-mtime ${MEASUREMENT_FILES_MTIME}"

MEASUREMENT_PREFIX="tcpflow/${HOSTNAME}"

echo "MEASUREMENT FILES MTIME: ${MEASUREMENT_FILES_MTIME}"

pushd ${BASE_DIR_WITH_MEASUREMENT}
  for f in $(find . -maxdepth 1 -type f ${MEASUREMENT_MODIFIED_IN_LAST} -printf '%f\n'); do
      swift upload --skip-identical --changed ${MEASUREMENT_CONTAINER} $f --object-name=${MEASUREMENT_PREFIX}/$f;
  done
popd
