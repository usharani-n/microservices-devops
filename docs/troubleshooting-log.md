# Troubleshooting log

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | user/order services unhealthy after `compose up` (`ECONNREFUSED :5672`, `404 no queue USER-isAuthenticate`) | RabbitMQ healthcheck passed before the port accepted connections; user-service consumes a queue created by product-service; `nodemon` kept crashed containers alive so restart policy never fired | healthcheck `check_port_connectivity`; `depends_on: product-service healthy`; run `node` directly |
| 2 | PR merged into `main` instead of `develop` | GitHub default branch was `main` | fast-forwarded `develop`, set `develop` as default branch |
| 3 | `lookup registry-1.docker.io: no such host` | temporary DNS/network problem on the workstation | restored network, pulled again |
| 4 | `container has no healthcheck configured` | working branch held the upstream compose file | restored the fixed file from the feature branch, merged via PR |
| 5 | `docker push` to ECR timed out (`timeout awaiting response headers`) | workstation hotspot upload about 3.5 KB/s (curl test) | build and push on EC2 with the instance role (traffic stays in AWS) |
| 6 | `push access denied ... insufficient_scope` | images named `docker.io/library/...`; the `IMAGE_PREFIX` change was not yet in `develop` | merged the change, rebuilt, verified names with `docker images` |
| 7 | SSH to EC2 timed out | security group allows one `/32`; the hotspot's public IP changed | helper script updates `admin_cidr` and applies Terraform; port 22 never opened to the world |
| 8 | pipeline stopped at *Validate configuration* | check matched `certifi/cacert.pem` in a tracked virtualenv (`myenv/`, public CA bundle) | untracked `myenv/`; check now looks for real private keys |
| 9 | pipeline failed at *Sync build server* (`port 22 timed out`) | stale workstation IP | refreshed `admin_cidr`; failure handling left the running version untouched |
| 10 | 502 on products/orders after a deployment; SSH closed during verification | Nginx resolves upstream names at load; recreated containers got new addresses | `nginx -s reload`; `deploy.sh` reloads before verifying; `retry(3)` on SSH deploy/rollback |
| 11 | `git@github.com: Permission denied (publickey)` intermittently | unreliable hotspot path to GitHub port 22 | retry loops, SSH over port 443 (`ssh.github.com`) |

## Simulated failures
- **Stopped container:** `docker compose stop order-service`. Grafana showed `orders` DOWN; `docker compose ps -a` showed the container exited; Nginx answered 502. Recovery: `docker compose start order-service`.
- **Failed deployment:** `./deploy.sh v9.9.9` failed at the pull (tag not found); nothing was changed and v1.0.0 kept running.
