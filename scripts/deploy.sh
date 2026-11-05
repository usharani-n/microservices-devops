#!/usr/bin/env bash
# Usage: ./deploy.sh <image-tag>   (runs on the EC2 host, in /opt/app)
set -euo pipefail
TAG="${1:?usage: deploy.sh <image-tag>}"
cd /opt/app

REGION=ap-south-1
REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${REGION}.amazonaws.com"
export IMAGE_PREFIX="${REGISTRY}/microservices-devops/"
export TAG

echo ">> logging in to ECR (instance role)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo ">> pulling images for tag $TAG"
docker compose pull user-service product-service order-service

echo ">> starting stack"
[ -f .current_tag ] && [ "$(cat .current_tag)" != "$TAG" ] && cp .current_tag .previous_tag || true
docker compose up -d --no-build --remove-orphans

echo ">> reloading nginx (re-resolve container addresses)"
docker compose exec -T nginx nginx -s reload || true

echo ">> verifying"
for i in $(seq 1 24); do
  if curl -fs http://localhost/health/users >/dev/null && \
     curl -fs http://localhost/health/products >/dev/null && \
     curl -fs http://localhost/health/orders >/dev/null; then
    echo "$TAG" > .current_tag
    echo "DEPLOY OK: $TAG"
    exit 0
  fi
  sleep 5
done
echo "DEPLOY FAILED: services not healthy; previous tag: $(cat .previous_tag 2>/dev/null || echo none)" >&2
exit 1
