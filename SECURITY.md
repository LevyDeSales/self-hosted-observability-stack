# Security Policy

This repository documents a self-hosted observability stack. It intentionally
contains examples and templates only. Do not publish real secrets, hostnames,
private IPs, push URLs, SMTP credentials, backup credentials, SSH keys, or
customer identifiers in issues, pull requests, discussions, or comments.

## Supported scope

Security reports are in scope when they affect:

- repository examples that could expose secrets by default;
- installation guidance that opens administrative services publicly;
- scripts that leak tokens or credentials in logs;
- GitHub workflow or publishing guidance that could commit sensitive files.

Operational incidents in your own deployment are out of scope for this public
repo, but documentation improvements that prevent the same issue are welcome.

## Reporting a vulnerability

Use GitHub private vulnerability reporting if it is enabled for this repository.
If private reporting is not available, open a public issue with a minimal
description and do not include exploit details, real infrastructure identifiers,
tokens, logs, or screenshots containing secrets.

## Secret handling

If you accidentally publish a secret:

1. Revoke or rotate the secret immediately.
2. Remove the value from the repository history before sharing the repo further.
3. Add or update an ignore rule or validation check so the same file cannot be
   committed again.

The docs in [docs/security.md](docs/security.md) describe the expected runtime
secret model.
