# Security policy

## Supported versions

| Version | Supported |
| --- | --- |
| 1.x | Yes. Security fixes and functional fixes on the latest minor release. |
| 0.1.x | Security fixes only, until 2026-12-31. Upgrade with [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md); only the pinned ref changes. |
| Unreleased `main` | Not supported for production use. |

## Reporting a vulnerability

Use GitHub private vulnerability reporting on this repository: open the Security tab and choose "Report a vulnerability". Do not open a public issue, pull request, or discussion for a security problem.

Include the module version or commit SHA, the inputs that reproduce the problem, the resulting plan, and the impact you see. Redact account IDs and internal names.

## What counts

- A validation bypass: a name component, root identifier, repository, environment, or tag that the module claims to reject at plan time but that reaches an output.
- A length bypass: a name longer than `name_max_length` reaching an output, or a name being truncated.
- A tag bypass: a `base_tags` entry overriding one of the canonical tags `Environment`, `ManagedBy`, `Repository`, or `Root`, or a blank tag key or value reaching `tags`.
- A silent rename: a different `name_prefix`, `names`, or `tags` value for the same inputs within a supported major version. Consumers derive live resource names from these values, so an unannounced change can replace or retag production resources.
- Non-determinism: an output that differs between runs, machines, or accounts for the same inputs.
- A dependency problem in the release pipeline that could publish unverified code.

Findings in your own inputs (for example a name that reveals an internal project) or in AWS services themselves are out of scope here; report the latter to AWS.

## Response

We acknowledge a report within 5 business days and keep you informed while we confirm, fix, and release. A fix ships as a patch release of every supported line with a `CHANGELOG.md` entry that credits the reporter unless they ask otherwise. Please give us a reasonable window before disclosing publicly.

## Security design

The module has no attack surface at runtime: it declares no provider, reads no data source, creates no resource, and holds no credential or secret. It is secure by construction through its inputs: names and identifiers accept only lowercase letters, digits, and hyphens, the environment is a closed list, the repository must be `owner/name`, tag keys and values cannot be blank, every name is checked against `name_max_length` and never truncated, and the canonical provenance tags cannot be overridden. Every claim is enforced by a validation or a precondition with a `terraform test` case behind it, and the values that live roots depend on are pinned by a golden-master test. The description is in the [Security model](README.md#security-model) section of the README, and the reasoning in [docs/DESIGN.md](docs/DESIGN.md).
