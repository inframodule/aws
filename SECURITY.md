# Security Policy

## Supported versions

Security fixes are applied to the latest tagged release of each module. Older releases may require an upgrade before receiving a fix.

| Module | Supported release |
|---|---|
| `alb` | `alb-v1.0.0` |
| `compute` | `1.0.0` |
| `s3` | `s3-v1.0.0` |
| `vpc` | `vpc-v1.0.0` |

This table is updated as new releases are published.

## Reporting a vulnerability

Do not disclose suspected vulnerabilities in a public issue, discussion, or pull request.

Use GitHub's private vulnerability reporting workflow from the repository's **Security** tab. Include:

- The affected module and version.
- The security impact and expected behavior.
- Reproduction configuration or steps with all credentials and customer data removed.
- Any known workarounds.
- Whether the issue is already public elsewhere.

If private vulnerability reporting is unavailable, open a public issue containing no vulnerability details and request a private contact channel.

Reports will be reviewed on a best-effort basis. Confirmed issues will be assessed for severity, fixed in supported versions, tested, and documented in release notes before coordinated disclosure.

## Security scope

Security reports may include:

- A secure default that can be bypassed unexpectedly.
- A module policy that grants broader access than documented.
- Sensitive data exposed through outputs, logs, state, or user data.
- Destructive behavior that occurs without an explicit guardrail.
- A dependency or provider interaction that creates a material vulnerability.

General hardening suggestions, feature requests, and questions can use normal GitHub issues.

## Deployment responsibility

These modules are building blocks, not a complete security program. Callers remain responsible for reviewing Terraform plans, protecting state, managing credentials, validating regional and organizational policies, monitoring deployed resources, and testing backup and recovery procedures.
