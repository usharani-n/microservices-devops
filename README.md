# Microservices CI/CD on AWS

Three existing microservices (user, product, order; source: github.com/koachcode/ecommerce-server) are delivered to AWS EC2 with GitHub, Jenkins, Docker Compose, Nginx, Terraform, Amazon ECR, Prometheus and Grafana. The application code is unchanged; this repository adds the DevOps layer.

## Architecture
~~~text
GitHub (develop) <-- Jenkins polls every 2 min -- Jenkins (workstation, Docker, 127.0.0.1:8090)
                                                     | SSH (key stored as a Jenkins credential)
                                                     v
 EC2 Ubuntu 24.04 (Terraform) --- IAM instance role ---> Amazon ECR (3 private repositories)
   /opt/app        Docker Compose
     nginx :80  ->  user-service :4002  /api/users
                ->  product-service :4001  /api/products
                ->  order-service :4000  /api/orders
     mongo, rabbitmq (internal only, named volumes)
   /opt/app/monitoring   Prometheus, Node Exporter, Blackbox Exporter, Grafana (127.0.0.1 only)
~~~

## Repository layout
- `user-service/`, `product-service/`, `order-service/`: application and Dockerfiles
- `docker-compose.yml`: services, network, volumes, healthchecks, restart policies, start order
- `nginx/`: reverse proxy configuration
- `infra/terraform/`: EC2, ECR, security group, IAM, key pair
- `monitoring/`: Prometheus, Grafana provisioning, monitoring Compose file
- `scripts/`: `deploy.sh`, `ci-build.sh`, `ci-release.sh`, `ci-rollback.sh`
- `Jenkinsfile`: the pipeline
- `docs/`: deployment components, branching, troubleshooting log

## Prerequisites
AWS account with a budget alert and an IAM admin user (not root), AWS CLI v2, Terraform >= 1.5, Docker, Git, an SSH key pair (`~/.ssh/devops-ec2`), Jenkins with the SSH Agent and Git plugins.

## Branching
`main` (releases, tagged), `develop` (integration, default), `feature/*` and `fix/*` merged by pull request. Secrets, `.env`, `*.tfvars`, state files and keys are never committed (`.gitignore`; the pipeline also checks).

## 1. Provision infrastructure
~~~bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars      # set admin_cidr to your public IP/32
terraform init && terraform validate && terraform plan -out=tfplan && terraform apply tfplan
~~~
Creates: 1 EC2 (t3.small, Ubuntu 24.04, IMDSv2 only; Docker, Compose and AWS CLI installed by user data), 3 ECR repositories, a security group (SSH from one IP only, HTTP 80), an IAM role and instance profile (ECR read, plus push to the three repositories), an SSH key pair, and a push-only IAM user. State is local and ignored by Git; production would use an S3 backend with locking.

## 2. First-time server setup
Clone this repository to `~/build` on the server and create `/opt/app` with `docker-compose.yml`, `nginx/`, `deploy.sh`. Create `/opt/app/.env` and `<service>/.env` from the `.env.example` templates with generated secrets (`openssl rand -hex`); they exist only on the server.

## 3. Deploy
Automatic: a push or merge to `develop` is detected by Jenkins polling and runs the pipeline:
1. Checkout (image tag = build number + git SHA)
2. Validate configuration (script syntax, no secret files tracked)
3. Run available tests (the application defines none)
4. Sync build server
5. Build, tag and push the three images to ECR (executed on the EC2 host with its IAM role, because the workstation's upload bandwidth is too low)
6. Deploy over SSH (`deploy.sh <tag>`: ECR login, pull, `docker compose up -d`, Nginx reload, health verification)
7. Verify from outside (`/healthz`, `/health/{users,products,orders}` return 200; running tag equals expected tag)

If a deployment fails after it started, `ci-rollback.sh` redeploys the last good tag. Manual deploy on the server: `cd /opt/app && ./deploy.sh <tag>`.

## 4. Rollback and recovery
Jenkins: Build with Parameters, `DEPLOY_TAG=<existing ECR tag>` (no build, redeploys that tag and verifies it). On the server: `./deploy.sh <previous-tag>` (`.current_tag` and `.previous_tag` record the history). Rollback restores images; Nginx and Compose configuration always come from the commit being deployed, so configuration is rolled back by reverting the commit through a pull request. Container failure: `docker compose ps -a`, `docker compose logs`, `docker compose start <service>`.

## 5. Verify
~~~bash
for p in healthz health/users health/products health/orders api/products; do curl -s -o /dev/null -w "$p -> %{http_code}\n" http://<EC2_IP>/$p; done
~~~

## 6. Monitoring
Prometheus, Node Exporter (CPU, memory, disk, network), Blackbox Exporter (availability and latency of the three services through Nginx) and Grafana run on the server and listen on 127.0.0.1 only. Access through a tunnel: `ssh -N -L 3000:localhost:3000 -L 9090:localhost:9090 -i ~/.ssh/devops-ec2 ubuntu@<EC2_IP>`, then open http://localhost:3000. Dashboard: "Microservices overview".

## Security notes
No AWS keys on the server (instance role) or in Jenkins (only an SSH key and the server address are stored). SSH is restricted to one `/32` address. Jenkins, Prometheus and Grafana are not exposed publicly. MongoDB and RabbitMQ are not published.

## Cleanup
~~~bash
cd infra/terraform
terraform plan -destroy        # review
terraform destroy              # removes EC2, ECR (with images), security group, IAM
~~~
Then delete the IAM access keys used for the CLI, stop Jenkins (`docker rm -f jenkins`) and remove its volume if no longer needed.

## Known limitations
The application has no automated tests and no `/metrics` endpoint, so application metrics are limited to availability and latency probes. The workstation's public IP changes, so SSH access needs `scripts`-free refresh of `admin_cidr` (`terraform apply`). Docker credentials on the build server are stored unencrypted (`config.json`). Node 18 is end-of-life.
