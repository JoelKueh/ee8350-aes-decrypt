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

# Use a single-line overall progress bar without per-file listing (rsync >= 3.1.0)
RSYNC_FLAGS=(-a)
if rsync --info=help >/dev/null 2>&1; then
    RSYNC_FLAGS+=(--info=progress2)
fi

# Push repo (skip .git, build, and MATLAB report files)
rsync "${RSYNC_FLAGS[@]}" --delete \
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
rsync "${RSYNC_FLAGS[@]}" \
  --exclude='csrc/' \
  --exclude='work/' \
  --exclude='simv.daidir/' \
  --exclude='obj_dir/' \
  --exclude='vcst_rtdb/' \
  "${REMOTE}:${REMOTE_DIR}/build/" ./build/

exit "${STATUS}"
