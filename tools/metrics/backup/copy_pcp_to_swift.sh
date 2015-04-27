#!/bin/bash
# Copy pcp files (to share or for a backup)

set -o nounset
set -o errexit
set -o pipefail

PMLOGGER_BASE_DIR="/var/log/pcp/pmlogger"
PMLOGGER_CONTAINER="experiments"
HOSTNAME=$(hostname)

pushd ${PMLOGGER_BASE_DIR}

  for f in $(find ${HOSTNAME} -maxdepth 1 -mindepth 1 -type f); do
    swift upload --skip-identical --changed ${PMLOGGER_CONTAINER} $f --object-name=pcp/$f;
  done

popd