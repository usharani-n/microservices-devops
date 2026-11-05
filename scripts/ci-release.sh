#!/usr/bin/env bash
# Runs on the server: publish compose/nginx/deploy files from the checked-out commit and deploy a tag.
set -euo pipefail
TAG="${1:?usage: ci-release.sh <image-tag>}"
cp -f ~/build/docker-compose.yml /opt/app/docker-compose.yml
mkdir -p /opt/app/nginx
cp -f ~/build/nginx/default.conf ~/build/nginx/proxy_params /opt/app/nginx/
cp -f ~/build/scripts/deploy.sh /opt/app/deploy.sh && chmod +x /opt/app/deploy.sh
/opt/app/deploy.sh "$TAG"
cd /opt/app
docker compose exec -T nginx nginx -s reload || true
echo "$(date -Is) $TAG" >> /opt/app/deploy-history.log
