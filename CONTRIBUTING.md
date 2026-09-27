# Contributing

Thank you for improving `aws.modules.naming`. This guide covers the toolchain, the local quality gate, how behaviour is tested and where it belongs, commit and pull request conventions, and how releases are cut.

## The one rule

The v1 interface is frozen. Live Terraform roots derive every resource name from `name_prefix` and `names` and their provider `default_tags` from `tags`; a change to any of those values for the same inputs renames or retags real resources. Within v1:

- Never change the name, type, default, or accepted values of an input, or the name, shape, or value of an output.
- Add an input or output only if it is optional and leaves every existing output unchanged for existing inputs.
- `tests/golden_master.tftest.hcl` must pass unchanged. If it fails, your change is a v2 change, not a test to update.
- A behaviour you think is wrong (the `default` key in `additional_names`, silent overriding of canonical tags) is already listed under "Deferred to v2" in [docs/DESIGN.md](docs/DESIGN.md). Do not fix it in v1; add to that list instead.

## Development setup

The module targets Terraform `>= 1.7.0, < 2.0.0` and is developed against 1.7.5, the version the consuming platform pins. It has no provider, so no credentials and no plugin cache are needed. Install the toolchain:

| Tool | Purpose | Install |
| --- | --- | --- |
| [tfenv](https://github.com/tfutils/tfenv) | Pin the Terraform version | `tfenv install 1.7.5 && tfenv use 1.7.5` |
| [tflint](https://github.com/terraform-linters/tflint) | Lint with the Terraform ruleset configured in `.tflint.hcl` | `brew install tflint && tflint --init` |
| [terraform-docs](https://terraform-docs.io) v0.20.0 | Generate the inputs and outputs tables in every README. Pinned to the version bundled by the CI docs action; newer releases change table formatting and fail the drift check (`make docs` refuses other versions). | Download the v0.20.0 binary from the [releases page](https://github.com/terraform-docs/terraform-docs/releases/tag/v0.20.0) |
| [checkov](https://www.checkov.io) | Static security policy | `pip install checkov` |
| [trivy](https://trivy.dev) | Misconfiguration scanning | `brew install trivy` |
| [pre-commit](https://pre-commit.com) | Run the gate on every commit | `pip install pre-commit && pre-commit install` |

Clone, initialise without a backend, and run the gate once to confirm the setup:

```sh
terraform init -backend=false -input=false
make check
```

## The local gate

`make check` is the default target and the same gate CI runs. It stops at the first failing target and must pass before you open a pull request.

| Target | What it runs |
| --- | --- |
| `make fmt` | `terraform fmt -check -recursive -diff` from the repository root. `make fmt-fix` rewrites the files instead. |
| `make validate` | `make init` (`terraform init -backend=false`) followed by `terraform validate` in the root and every example directory. |
| `make lint` | `tflint --init` and then `tflint` in every directory with the root `.tflint.hcl`: documented and typed variables, documented outputs, snake_case naming, no unused declarations, pinned required versions. |
| `make test` | `terraform test` in the root and in every example. No credentials are needed. |
| `make docs` | `terraform-docs -c .terraform-docs.yml` in every directory, regenerating the tables between the `BEGIN_TF_DOCS` and `END_TF_DOCS` markers. Run it after touching any variable or output. |
| `make docs-check` | The same in `--output-check` mode: fails when a README is out of date. This is the variant `make check` and CI run. |
| `make security` | `checkov -d . --framework terraform`, and `trivy config --severity HIGH,CRITICAL` when trivy is on the PATH. There are no suppressions. |
| `make check` | `fmt`, `validate`, `lint`, `test`, `docs-check`, `security`, in that order. |
| `make clean` | Remove local `.terraform` directories. |

There is no `make lock` and no lock file: the module and its examples use no provider (`terraform_data` is built into Terraform). There is no integration target either. The module creates no AWS resource, so there is nothing to apply; every test is a plan.

## Test-first workflow

Every behaviour in this module is pinned by a test before it is implemented. Write the failing `run` block first, then the code, then run `make test`.

- Tests live in `tests/*.tftest.hcl`, one file per concern: `golden_master` (the live platform contract), `validation` (every variable validation), and `outputs` (names, the length precondition, tag precedence). Each example has its own `tests/example.tftest.hcl`. Each file starts with a `variables` block holding a valid baseline; each `run` overrides only what it exercises.
- Use `command = plan`. There is no provider, so tests run in a second and in CI without credentials.
- Validations are tested with `expect_failures`. Point it at the object that carries the check: `[var.root]` for a variable validation, `[output.names]` for the `name_max_length` precondition (Terraform 1.7.5 supports output values there). A run with `expect_failures` passes only if exactly those objects fail; add a positive run alongside so the accepted boundary is covered too. `expect_failures` cannot name an object inside a module call, so an example cannot test the module's own failures; the root tests do.
- `||` and `&&` do not short-circuit in Terraform 1.7. Both operands are always evaluated, so `x == null || length(x) > 0` fails when `x` is null. Guard with a conditional instead: `x == null ? false : length(x) > 0`. The validations for `name_components`, `additional_names`, and `base_tags` are written this way so a null element is rejected with the variable's message.
- Keep assertion `error_message` text a statement of the guaranteed behaviour. It becomes the documentation of the contract when a test fails. Assertions in `golden_master` must say that a change breaks live resource names.
- When you change validation logic, also compare it against the previous release: run the new tests against the old code (`git archive <tag> | tar -x -C <dir>`), which must pass for every case the old code handled, and confirm the accepted and rejected sets are the same.

## Where to add a feature

The module has no submodules; concerns are split by file, and each file has one reason to change.

| Concern | Lives in |
| --- | --- |
| A rule for what an input accepts | `variables.tf`, with a description, type, and validation whose message names the input; a passing and an `expect_failures` run in `tests/validation.tftest.hcl`. |
| How names or tags are derived | `locals.tf`, with the behaviour pinned in `tests/outputs.tftest.hcl` and, when it can affect a live root, in `tests/golden_master.tftest.hcl`. |
| Outputs and the length precondition | `outputs.tf`; every output has a description, and a change is asserted in `tests/outputs.tftest.hcl`. |
| A way of using the module worth showing | `examples/<name>/` with `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, and `tests/example.tftest.hcl`; add it to the matrix in `.github/workflows/terraform-quality.yml`. |

Rules that apply everywhere: no provider, no resource, no data source, no randomness, no clock; every variable has a description, a type, and a validation where a wrong value would otherwise be accepted silently; every output has a description; names are rejected when too long, never truncated.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). The scope is the file or concern the change touches.

```text
feat(variables): accept an optional name_suffix component list
fix(variables): reject a null tag value with the validation message
docs: explain tag precedence in the README
test(outputs): cover the exact-fit name_max_length boundary
feat!: reserve the default key in additional_names
```

Append `!` after the type or scope for a breaking change and add a `BREAKING CHANGE:` footer explaining what consumers must do. Breaking changes ship only in a major release with an entry in the upgrade guide.

## Pull request checklist

- [ ] `make check` passes locally.
- [ ] `tests/golden_master.tftest.hcl` passes unchanged.
- [ ] New behaviour has a test; changed validations have both a passing and an `expect_failures` run.
- [ ] Variables and outputs have descriptions; `make docs` regenerated the README tables.
- [ ] `CHANGELOG.md` has an entry under `## [Unreleased]` in the right category.
- [ ] Breaking changes carry `!`, a `BREAKING CHANGE:` footer, and an update to `docs/UPGRADE-<major>.md`.
- [ ] Examples still initialise, validate, and pass their tests; a new feature worth showing has an example.
- [ ] No provider, resource, or data source added.

## Release process

Releases are cut by maintainers.

1. Move the `## [Unreleased]` entries in `CHANGELOG.md` under a new `## [X.Y.Z] - YYYY-MM-DD` heading, add its compare link, and merge that change to `main`.
2. Create a signed annotated tag on the merge commit. The signing key must be registered with GitHub so the tag shows as Verified:

   ```sh
   git tag -s vX.Y.Z -m "aws.modules.naming vX.Y.Z"
   git push origin vX.Y.Z
   ```

3. Dispatch the `module-release` workflow (`.github/workflows/module-release.yml`) from the tag with `release_tag = vX.Y.Z`: `gh workflow run module-release.yml --ref vX.Y.Z -f release_tag=vX.Y.Z`. It verifies the signed tag, formatting, validation, tests, and generated docs, then publishes the GitHub release. Never dispatch it from `main`: the workflow checks that the tag points at the revision it checked out, and a maintenance release of an older line is cut from that line's commit.
4. Announce the release with the commit SHA. Consumers pin that SHA, not the tag:

   ```hcl
   source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=<commit-sha>" # vX.Y.Z
   ```

Tags are never moved or deleted once published. A bad release is followed by a new patch release.
