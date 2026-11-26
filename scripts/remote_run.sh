#!/usr/bin/env bash
set -euo pipefail

REMOTE="${REMOTE:-vlsi}"
REMOTE_DIR="${REMOTE_DIR:-/home/kuehn348/src/ee8350/aes-decode-remote}"
TARGET="${1:?Usage: $0 <make-target> [make-args...]}"
shift

# Push source to the remote directory
rsync -av --delete \
  --exclude='.git/' \
  --exclude='build/' \
  --exclude='html/' \
  --exclude='interface/' \
  --exclude='*.mat' \
  --exclude='*.mldatx' \
  ./ "${REMOTE}:${REMOTE_DIR}/"

# Run the Makefile target on the remote machine
set +e
ssh "${REMOTE}" "zsh -lc 'cd ${REMOTE_DIR} && make ${TARGET} $*'"
STATUS=$?
set -e

# 3. Pull logs, reports, and waveforms back (skip heavy caches)
mkdir -p build
rsync -av \
  --exclude='csrc/' \
  --exclude='work/' \
  --exclude='simv.daidir/' \
  --exclude='vcst_rtdb/' \
  "${REMOTE}:${REMOTE_DIR}/build/" ./build/

exit "${STATUS}"
