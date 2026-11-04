#!/usr/bin/env bash
# Runs on the server after a failed pipeline deployment: redeploy the last good tag.
set -euo pipefail
FAILED_TAG="${1:?usage: ci-rollback.sh <failed-tag>}"
cd /opt/app
cur="$(cat .current_tag 2>/dev/null || true)"
prev="$(cat .previous_tag 2>/dev/null || true)"
if [ "$cur" = "$FAILED_TAG" ] && [ -n "$prev" ]; then target="$prev"; else target="$cur"; fi
[ -n "$target" ] || { echo "no known good tag to roll back to"; exit 1; }
echo ">> rolling back to $target"
./deploy.sh "$target"
