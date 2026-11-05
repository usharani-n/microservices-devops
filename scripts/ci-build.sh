#!/usr/bin/env bash
# Runs on the build server inside ~/build: validate, build, tag and push the 3 images to ECR.
set -euo pipefail
TAG="${1:?usage: ci-build.sh <image-tag>}"
cd ~/build
REGION=ap-south-1
REGISTRY="$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${REGION}.amazonaws.com"
export IMAGE_PREFIX="${REGISTRY}/microservices-devops/"
export TAG

# placeholder env files so compose can parse and build (real secrets live only in /opt/app)
[ -f .env ] || cp .env.example .env
for s in user product order; do [ -f $s-service/.env ] || cp $s-service/.env.example $s-service/.env; done

echo ">> validating compose file"
docker compose config -q

echo ">> logging in to ECR (instance role)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo ">> building images with tag $TAG"
docker compose build user-service product-service order-service

echo ">> pushing images"
docker compose push user-service product-service order-service
echo "BUILD OK: $TAG"
