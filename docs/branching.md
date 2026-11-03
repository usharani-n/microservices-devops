# Branch workflow

- `main`: release-ready code only; updated by pull request from `develop`, then tagged (v1.0.0).
- `develop`: integration branch and GitHub default branch.
- `feature/<name>`: one branch per piece of work (docker-compose, nginx-proxy, terraform, jenkins, monitoring). Merged into `develop` by pull request.
- Commits use prefixes: feat:, fix:, docs:, chore:.
- Secrets: .env, *.pem, *.tfstate and *.tfvars are in .gitignore; only .env.example templates are committed.
- Jenkins trigger: SCM polling every 2 minutes (the Jenkins server runs on a private workstation and is not exposed to the internet).
