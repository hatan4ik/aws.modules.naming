# Changelog

All notable changes to this module are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). Consumers pin the commit SHA of a release tag; see [Versioning and releases](README.md#versioning-and-releases).

## [Unreleased]

## [1.0.0] - 2026-09-27

Interface-compatible release. Every input and output of 0.1.0 keeps its name, type, default, and behaviour, and returns the same value for the same inputs, because live Terraform roots derive every resource name from `name_prefix` and `names` and their provider `default_tags` from `tags`. A consumer upgrades by changing the pinned ref only; [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md) shows the edit. There are no resources, so no `moved` blocks and no state operations exist.

### Added

- `tests/golden_master.tftest.hcl`, pinning the exact `name_prefix`, `names`, and `tags` of the three live sandbox roots (`sandbox-network`, `sandbox-platform`, `sandbox-workload`) and the resource names they derive from them. Its failure messages state that a change breaks live resource names.
- `tests/validation.tftest.hcl`, with accepted boundary values and an `expect_failures` case for every variable validation.
- `tests/outputs.tftest.hcl`, covering the default and additional names, empty and multi-key `additional_names`, the `name_max_length` precondition through `expect_failures = [output.names]`, tag precedence, and the current behaviour of an `additional_names` key named `default`.
- Examples `minimal`, `platform-root`, and `multi-environment`, each with its own tests.
- `docs/DESIGN.md` (the frozen-interface decision, out-of-scope list, and the changes deferred to v2), `docs/UPGRADE-1.0.md`, `CONTRIBUTING.md`, `SECURITY.md`, and `LICENSE` (Apache-2.0).
- A README with the naming contract, tag precedence, and generated inputs and outputs reference.
- The `Makefile` quality gate, pre-commit, tflint, and terraform-docs configuration, Dependabot, issue and pull request templates, and the `module-release` workflow.

### Changed

- A `null` component in `name_components` or an `additional_names` list, or a `null` value in `base_tags`, is rejected by the variable's own validation message instead of an `Invalid function argument` error from inside the validation expression. The set of accepted and rejected inputs is unchanged.
- The `name_max_length` precondition on `names` now lists each offending name with its length. The rule is unchanged.
- The `base_tags` description states that the input is optional and that the canonical tags override a same-named key. Behaviour is unchanged.
- CI runs the shared `terraform-quality` workflow over the root and every example, with a docs drift check, in place of the hand-written workflow.
- `versions.tf` states that the module declares no provider.

### Removed

- Nothing. No input, output, or behaviour is removed.

## [0.1.0] - 2026-09-22

### Added

- Deterministic AWS naming and tags: validated `environment`, `root`, `repository`, `name_components`, `additional_names`, `name_separator`, `name_max_length`, `base_tags`, and `managed_by` inputs; `name_prefix`, `names` (with a length precondition), and `tags` outputs.
- A single Terraform test and a formatting, validation, and test workflow.

[Unreleased]: https://github.com/hatan4ik/aws.modules.naming/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/hatan4ik/aws.modules.naming/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/hatan4ik/aws.modules.naming/releases/tag/v0.1.0
