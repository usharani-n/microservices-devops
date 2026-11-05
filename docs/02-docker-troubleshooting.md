# Docker troubleshooting notes

## Incident 1: user-service and order-service unhealthy after `docker compose up`
- Symptom: containers "Up" but `unhealthy`; no response on /api-docs/.
- Logs: `ECONNREFUSED :5672` (RabbitMQ), later `404 NOT_FOUND no queue 'USER-isAuthenticate'`.
- Root cause 1: RabbitMQ healthcheck (`ping`) passed before port 5672 accepted connections.
  Fix: use `rabbitmq-diagnostics -q check_port_connectivity`.
- Root cause 2: user-service consumes a queue that product-service creates.
  Fix: `depends_on: product-service (service_healthy)` for user-service.
- Root cause 3: `nodemon` keeps the container alive after a crash, so `restart: unless-stopped`
  never triggered. Fix: run `node ./src/index.js` directly via compose `command`.
- Verification: `docker compose down && up -d` three times; all 5 containers healthy.

## Design notes
- No /health endpoint in the app; healthchecks use the existing /api-docs/ page (no app code changed).
- Mongo and RabbitMQ ports are not published to the host.
- Secrets live in untracked .env files; only .env.example templates are committed.

## Nginx reverse proxy
- Single entry point on port 80: /api/users -> user-service:4002, /api/products -> product-service:4001, /api/orders -> order-service:4000.
- App ports are no longer published to the host; only Nginx (80) is reachable.
- /health/{users,products,orders} proxy to each service's /api-docs/ and are used later to verify deployments.
- Nginx healthcheck uses 127.0.0.1 (localhost resolved to IPv6 inside the Alpine image and failed).

## Incident 2: PR merged into main instead of develop
- Cause: GitHub's default branch was main, so the PR base defaulted to it.
- Fix: develop fast-forwarded to main; develop set as default branch.

## Incident 3: Docker Hub unreachable (DNS)
- Symptom: `lookup registry-1.docker.io: no such host` when pulling nginx.
- Fix: restored network/DNS, then pulled again.
