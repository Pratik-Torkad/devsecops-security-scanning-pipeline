# Security Policy

## Scope

This is a learning repository demonstrating DevSecOps scanning. It is not a production deployment template.

## Reporting a vulnerability

Do not disclose credentials, tokens, private keys, or exploitable details in public issues. Use GitHub's private vulnerability reporting feature for this repository when available.

## Safe use

- Never commit live credentials, access keys, personal access tokens, kubeconfig files, or private keys.
- Use short-lived credentials and least-privilege access for external services.
- Do not run Terraform apply from this repository without reviewing the plan and intended AWS charges.
- Treat scanner findings as actionable. Confirm false positives before suppressing them.
- Keep scanner versions and GitHub Actions updated.
- Do not use real secrets in sample tests, documentation, or fixtures.
