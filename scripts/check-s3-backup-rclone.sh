#!/usr/bin/env bash
set -euo pipefail

env_file="${1:-/etc/observability-stack/backup.env}"

if [ -f "$env_file" ]; then
  # shellcheck disable=SC1090
  source "$env_file"
fi

: "${UPTIME_KUMA_PUSH_URL:?Set UPTIME_KUMA_PUSH_URL}"
: "${RCLONE_REMOTE_PATH:?Set RCLONE_REMOTE_PATH}"
: "${MAX_AGE_HOURS:=26}"
: "${MIN_SIZE_BYTES:=1}"
: "${RCLONE_BIN:=rclone}"

push_base="${UPTIME_KUMA_PUSH_URL%%\?*}"

send_push() {
  local status="$1"
  local msg="$2"
  msg="${msg// /%20}"
  msg="${msg//:/%3A}"
  curl -fsS "${push_base}?status=${status}&msg=${msg}&ping=" >/dev/null
}

rclone_args=()
if [ -n "${RCLONE_CONFIG_FILE:-}" ]; then
  rclone_args+=(--config "$RCLONE_CONFIG_FILE")
fi

if ! latest="$(
  "$RCLONE_BIN" "${rclone_args[@]}" lsf \
    --max-age "${MAX_AGE_HOURS}h" \
    --files-only \
    --recursive \
    --format sp \
    "$RCLONE_REMOTE_PATH" 2>/dev/null |
    awk -F';' -v min="$MIN_SIZE_BYTES" '$1 + 0 >= min { print; exit }'
)"; then
  send_push down "rclone failed"
  exit 1
fi

if [ -z "$latest" ]; then
  send_push down "no recent non-empty backup"
  exit 1
fi

send_push up "backup found"
