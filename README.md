# DevSecOps Security Scanning Pipeline

A practical DevSecOps pipeline that scans application code, container images, Terraform and Kubernetes manifests for exposed secrets, known vulnerabilities and security misconfigurations.

## Security toolchain

| Tool | Purpose | Output |
|---|---|---|
| Gitleaks | Scans complete Git history for exposed credentials and tokens | SARIF |
| Trivy | Scans filesystems, dependencies, images, secrets and IaC configuration | SARIF |
| Checkov | Checks Terraform, Kubernetes and Dockerfile security policies | SARIF |
| GitHub Code Scanning | Displays compatible SARIF findings in the repository Security tab | Alerts |

## Architecture

~~~mermaid
flowchart TD
  Push[Push or Pull Request] --> Tests[Python unit tests]
  Push --> Secrets[Gitleaks full-history scan]
  Push --> IaC[Checkov and Trivy filesystem scan]
  Tests --> Build[Build Docker image]
  Build --> Image[Trivy image scan]
  Secrets --> Reports[SARIF reports]
  IaC --> Reports
  Image --> Reports
  Reports --> GH[GitHub Code Scanning and workflow artifacts]
~~~

## Repository layout

~~~text
.
├── .github/workflows/devsecops.yml
├── app.py
├── requirements.txt
├── requirements-dev.txt
├── tests/test_app.py
├── Dockerfile
├── terraform/
│   ├── providers.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── kubernetes/
│   ├── deployment.yaml
│   └── service.yaml
├── SECURITY.md
└── README.md
~~~

## 1. Run the demo application

Requires Python 3.12 or later.

~~~bash
python -m venv .venv
~~~

Activate the environment:

~~~bash
# Linux/macOS
source .venv/bin/activate

# Windows PowerShell
.venv\Scripts\Activate.ps1
~~~

Install dependencies and start the application:

~~~bash
pip install -r requirements-dev.txt
python -m flask --app app run --host 0.0.0.0 --port 8080
~~~

Open http://localhost:8080 and http://localhost:8080/health.

Run tests:

~~~bash
pytest -q
~~~

## 2. Build and scan the Docker image locally

~~~bash
docker build -t devsecops-demo:local .
docker run --rm -p 8080:8080 devsecops-demo:local
~~~

Scan the image with Trivy:

~~~bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$HOME/.cache/trivy:/root/.cache/" aquasec/trivy:0.76.1 image --scanners vuln --severity HIGH,CRITICAL devsecops-demo:local
~~~

## 3. Run Gitleaks locally

The workflow scans the complete Git history, not just the current working tree.

~~~bash
docker run --rm -v "$PWD:/repo" -w /repo ghcr.io/gitleaks/gitleaks:v8.30.1 git . --redact --report-format sarif --report-path /repo/gitleaks.sarif
~~~

Never put real secrets in test files or commit history, even as examples.

## 4. Run Checkov locally

~~~bash
docker run --rm -v "$PWD:/repo" -w /repo ghcr.io/bridgecrewio/checkov:3.3.29 -d /repo --framework terraform,kubernetes,dockerfile
~~~

Review findings and apply recommended remediations instead of suppressing checks without justification.

## 5. Run Trivy filesystem and configuration scans

~~~bash
docker run --rm -v "$PWD:/repo" aquasec/trivy:0.76.1 fs --scanners vuln,misconfig,secret --severity HIGH,CRITICAL /repo
~~~

## 6. Terraform validation (no cloud deployment)

Requires Terraform 1.10 or later.

~~~bash
cd terraform
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
~~~

The Terraform example describes a private S3 artifact bucket with public access blocked, versioning and server-side encryption. It is provided for static scanning only. This project does not run terraform apply or create AWS resources.

## 7. Kubernetes manifest validation

~~~bash
kubectl apply --dry-run=client -f kubernetes/deployment.yaml
kubectl apply --dry-run=client -f kubernetes/service.yaml
~~~

The Deployment uses a non-root user, read-only root filesystem, dropped Linux capabilities, resource limits and health probes.

For a local kind cluster, build and load the image:

~~~bash
docker build -t devsecops-demo:local .
kind load docker-image devsecops-demo:local
kubectl apply -f kubernetes/
kubectl get pods
~~~

## 8. GitHub Actions workflow

The workflow runs on pushes to main, pull requests and manual dispatch.

- Python unit tests run before the image is built.
- Gitleaks scans full Git history and blocks the job when it finds a secret.
- Checkov scans Terraform, Kubernetes and Dockerfile configuration.
- Trivy scans repository files and the built Docker image.
- SARIF reports are uploaded to GitHub Code Scanning.
- Reports are saved as workflow artifacts for 14 days.

**Initial policy:** Gitleaks is blocking. Checkov and Trivy begin in report-only mode (Checkov soft-fail and Trivy exit-code 0) to establish a findings baseline. After findings are reviewed and remediated, remove Checkov's soft-fail option and set Trivy's exit-code to 1 to enforce a vulnerability and misconfiguration gate.

GitHub Code Scanning requires the workflow's security-events: write permission. Review alerts under the repository Security → Code scanning tab.

## Security and cost

- The pipeline does not connect to AWS or create cloud resources.
- GitHub Actions uses the built-in token with repository read access and Code Scanning write access.
- Never add AWS keys, passwords, personal access tokens, private keys, kubeconfig files, or production credentials.
- The container image is built and scanned on the runner; it is not published to a registry.
- Keep scanner versions and GitHub Actions updated.

## Tool versions

- Trivy 0.76.1
- Checkov 3.3.29
- Gitleaks 8.30.1
- GitHub CodeQL upload-sarif action v4

Re-check upstream releases before upgrading.
