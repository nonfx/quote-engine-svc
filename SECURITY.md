# Security Policy

## Supported Versions

The `main` branch is the only supported version of `quote-engine-svc`.

## Reporting a Vulnerability

If you discover a security vulnerability, please report it privately:

- Open a [GitHub security advisory](https://github.com/nonfx/quote-engine-svc/security/advisories/new), or
- Email the maintainers listed in `.github/CODEOWNERS`.

Please do **not** open a public issue for security reports. We aim to
acknowledge reports within 3 business days and to provide a remediation
timeline within 10 business days.

## Secure Development Practices

This repository enforces, on the `main` branch:

- Branch protection requiring at least two approving reviews including a Code Owner.
- Signed, verified commits and a linear history.
- Required status checks: lint, unit tests, build, CodeQL (SAST),
  dependency review (SCA), and gitleaks (secret scanning).
- Secret scanning with push protection, and Dependabot alerts.
