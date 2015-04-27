#!/bin/bash
# Copy pcp files (to share or for a backup)

set -o nounset
set -o errexit
set -o pipefail

PMLOGGER_BASE_DIR="/var/log/pcp/pmlogger"
PMLOGGER_CONTAINER="experiments"
HOSTNAME=$(hostname)

PCP_FILES_MTIME=${PCP_FILES_MTIME:-1}
PCP_MODIFIED_IN_LAST="-mtime ${PCP_FILES_MTIME}"

echo "PCP FILES MTIME: ${PCP_FILES_MTIME}"

pushd ${PMLOGGER_BASE_DIR}

  for f in $(find ${HOSTNAME} ${PCP_MODIFIED_IN_LAST} -maxdepth 1 -mindepth 1 -type f); do
    swift upload --skip-identical --changed ${PMLOGGER_CONTAINER} $f --object-name=pcp/$f;
  done

popd
