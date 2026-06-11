#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

for script in scripts/*.sh; do
  bash -n "$script"
done

for env_example in examples/env/*.env.example; do
  (
    set -u
    # shellcheck disable=SC1090
    source "$env_example"
  )
done

forbidden_patterns="${FORBIDDEN_PATTERNS:-}"
if [ -n "$forbidden_patterns" ]; then
  if rg -n --glob '!scripts/validate-repo.sh' "$forbidden_patterns" .; then
    echo "Found forbidden private reference patterns. Replace them before publishing." >&2
    exit 1
  fi
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  set -a
  # shellcheck disable=SC1091
  source examples/env/central.env.example
  # shellcheck disable=SC1091
  source examples/env/remote-agent.env.example
  set +a

  docker compose -f examples/docker-compose/uptime-kuma.dokploy.yml config >/dev/null
  docker compose -f examples/docker-compose/beszel-hub-agent.dokploy.yml config >/dev/null
  docker compose -f examples/docker-compose/beszel-agent.remote.yml config >/dev/null
elif [ "${REQUIRE_DOCKER:-0}" = "1" ]; then
  echo "Docker Compose validation required but docker compose is unavailable." >&2
  exit 1
else
  echo "Docker not found; skipped Compose validation." >&2
fi

echo "Validation passed."
