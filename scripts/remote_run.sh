#!/usr/bin/env bash
set -euo pipefail

REMOTE="vs"
REMOTE_DIR="/home/kuehn348/src/ee8350/aes-decode-remote"

# Parse arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <command...>" >&2
    exit 1
fi
printf -v CMD '%q ' "$@"

# Push repo (skip .git, build, and MATLAB report files)
rsync -av --delete \
  --exclude='.git/' \
  --exclude='build/' \
  --exclude='html/' \
  --exclude='interface/' \
  --exclude='*.mat' \
  --exclude='*.mldatx' \
  ./ "${REMOTE}:${REMOTE_DIR}/"

# Run the command on the remote directory
set +e
ssh "${REMOTE}" "zsh -lc 'cd ${REMOTE_DIR} && ${CMD}'"
STATUS=$?
set -e

# Pull logs back and skip heavy cache directories
mkdir -p build
rsync -av \
  --exclude='csrc/' \
  --exclude='work/' \
  --exclude='simv.daidir/' \
  --exclude='obj_dir/' \
  --exclude='vcst_rtdb/' \
  "${REMOTE}:${REMOTE_DIR}/build/" ./build/

exit "${STATUS}"
