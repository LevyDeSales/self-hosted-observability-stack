#!/usr/bin/env bash
set -euo pipefail

env_file="${1:-/etc/observability-stack/containers.env}"

if [ -f "$env_file" ]; then
  # shellcheck disable=SC1090
  source "$env_file"
fi

: "${UPTIME_KUMA_PUSH_URL:?Set UPTIME_KUMA_PUSH_URL}"
: "${REQUIRED_CONTAINERS:?Set REQUIRED_CONTAINERS}"
: "${HEALTHCHECK_CONTAINERS:=}"
: "${DOCKER_BIN:=docker}"

push_base="${UPTIME_KUMA_PUSH_URL%%\?*}"

send_push() {
  local status="$1"
  local msg="$2"
  msg="${msg// /%20}"
  msg="${msg//:/%3A}"
  curl -fsS "${push_base}?status=${status}&msg=${msg}&ping=" >/dev/null
}

normalize_list() {
  local raw="$1"
  raw="${raw//,/ }"
  printf '%s\n' "$raw"
}

required_containers="$(normalize_list "$REQUIRED_CONTAINERS")"
healthcheck_containers=" $(normalize_list "$HEALTHCHECK_CONTAINERS" | tr '\n' ' ') "

for container in $required_containers; do
  state="$("$DOCKER_BIN" inspect -f '{{.State.Status}}' "$container" 2>/dev/null || true)"
  if [ "$state" != "running" ]; then
    send_push down "${container} ${state:-missing}"
    exit 1
  fi

  case "$healthcheck_containers" in
    *" $container "*)
      health="$("$DOCKER_BIN" inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || true)"
      if [ "$health" != "healthy" ]; then
        send_push down "${container} health ${health:-missing}"
        exit 1
      fi
      ;;
  esac
done

send_push up "OK"
