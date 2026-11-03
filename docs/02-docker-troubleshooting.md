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
