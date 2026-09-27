# aws.modules.naming

Deterministic, validated names and a canonical tag map for AWS Terraform roots. From an environment, a root identifier, a repository, and lists of name components, the module emits a default name (`name_prefix`), any number of additional names keyed by a logical identifier (`names`), and the tags every resource should carry (`tags`). It rejects a name that is too long instead of truncating it, never generates a random suffix, has no provider, reads no data source, and creates no resource, so it works offline and returns the same value for the same input everywhere. Requires Terraform >= 1.7.

The v1 interface is **frozen** and identical to v0.1.0: live platform roots derive every resource name from these outputs, so a change to a value would rename real resources. See [Compatibility promise](#compatibility-promise).

## Why this module

- One rule for names. Components are lowercase letters, digits, and hyphens, joined with `-`. Uppercase, whitespace, underscores, empty components, and a leading or trailing hyphen fail the plan with a message that names the input.
- Names fail, never shorten. `name_max_length` (default 63, up to 128) is checked for every emitted name. A name that is too long fails the plan and the message lists each offending name with its length; nothing is truncated, so two components can never silently collide.
- Names for neighbouring roots without repeating the rule. `additional_names` derives the names of the roots this one refers to (a VPC, a cluster, a workload) from the same validated rule, keyed by a stable identifier.
- Provenance tags that cannot be overridden. `Environment`, `ManagedBy`, `Repository`, and `Root` are always present and always carry the module's values; a same-named key in `base_tags` does not win. Allocation tags (`Application`, `CostCenter`, `Owner`, and so on) pass through unchanged and must not be blank.
- Nothing to configure or leak. No provider, no credentials, no data sources, no resources, no randomness: the outputs are pure functions of the inputs.
- A compatibility guarantee you can run. `tests/golden_master.tftest.hcl` pins the exact `name_prefix`, `names`, and `tags` of the three live sandbox roots, and its failure messages say that a change breaks live resource names.

## Quick start

```hcl
module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=<commit-sha>" # v1.0.0

  environment     = "dev"
  root            = "sandbox-platform"
  repository      = "hatan4ik/devops-aws-infra"
  name_components = ["sandbox", "platform", "dev"]

  additional_names = {
    network = ["sandbox", "network", "dev"]
  }

  base_tags = {
    Application = "platform"
    CostCenter  = "platform-bootstrap"
    Owner       = "hatan4ik"
  }
}

provider "aws" {
  default_tags {
    tags = module.naming.tags
  }
}

resource "aws_ecs_cluster" "platform" {
  name = "${module.naming.name_prefix}-cluster"
}
```

This yields `name_prefix = "sandbox-platform-dev"`, `names = { default = "sandbox-platform-dev", network = "sandbox-network-dev" }`, and tags `Application`, `CostCenter`, `Owner`, plus `Environment = "dev"`, `ManagedBy = "terraform"`, `Repository = "hatan4ik/devops-aws-infra"`, `Root = "sandbox-platform"`.

## Architecture

```text
root (no resources, no providers)
├── variables.tf   Nine inputs, each validated at plan time.
├── locals.tf      name_component_sets, names, tags.
├── outputs.tf     name_prefix, names (with the name_max_length precondition), tags.
└── versions.tf    Terraform >= 1.7.0, < 2.0.0.
```

1. `name_components` becomes the `default` entry; `additional_names` entries are added beside it, each a complete component list.
2. Every list is joined with `-` into a name.
3. `name_prefix` is `names.default`.
4. `tags` is `base_tags` merged with the four canonical tags.
5. The `names` output carries a precondition: every name is at most `name_max_length` characters. It is evaluated whenever the module is, whichever output the caller reads.

## Naming contract

Inputs. Every rule is a plan-time validation; a violation names the input and stops the plan.

| Input | Type | Default | Rule | Valid | Invalid |
| --- | --- | --- | --- | --- | --- |
| `environment` | `string` | none | One of `dev`, `staging`, `prod`, `shared`, `global`, `sandbox`. | `dev` | `Dev`, `test`, `""` |
| `root` | `string` | none | Lowercase kebab-case: starts with a letter or digit, then letters, digits, and hyphens; does not end with a hyphen. | `sandbox-platform` | `Sandbox`, `-a`, `a-`, `a_b`, `a b` |
| `repository` | `string` | none | `owner/name`: two non-empty segments, one slash, no whitespace. | `hatan4ik/devops-aws-infra` | `infra`, `a/b/c`, `a/`, `a b/c` |
| `name_components` | `list(string)` | none | One or more components, each valid as for `root`. | `["sandbox", "platform", "dev"]` | `[]`, `["Sandbox"]`, `["a-"]`, `[null]` |
| `additional_names` | `map(list(string))` | `{}` | Key `[a-z][a-z0-9_]*`; each value a non-empty component list, each component valid as for `root`. | `{ network = ["sandbox", "network", "dev"] }` | `{ Network = [...] }`, `{ "1n" = [...] }`, `{ n = [] }` |
| `name_separator` | `string` | `"-"` | Exactly `-`. | `-` | `_`, `.`, `""` |
| `name_max_length` | `number` | `63` | From 1 to 128. Applies to every emitted name. | `32` | `0`, `129` |
| `base_tags` | `map(string)` | `{}` | Keys and values not blank (not empty, not only whitespace). | `{ Owner = "hatan4ik" }` | `{ Owner = "" }`, `{ "" = "x" }` |
| `managed_by` | `string` | `"terraform"` | Not blank. | `opentofu` | `""`, `"  "` |

Passing `null` for an input that has a default selects the default: every input is declared `nullable = false`.

Outputs.

| Output | Value |
| --- | --- |
| `name_prefix` | The default name: `name_components` joined with `-`. Equal to `names.default`. |
| `names` | An object: `default` plus one entry per `additional_names` key, each the joined name. Every value is at most `name_max_length` characters, or the plan fails. |
| `tags` | `base_tags` plus `Environment`, `ManagedBy`, `Repository`, and `Root`. |

Two behaviours to know, both inherited from v0.1.0 and kept because changing them would change what a valid input returns (they are listed under "Deferred to v2" in [docs/DESIGN.md](docs/DESIGN.md)):

- A key named `default` in `additional_names` replaces the component list that produces `name_prefix`, because `additional_names` is merged last. Do not use `default` as a key.
- The module does not check tags against AWS limits (the reserved `aws:` prefix, 128-character keys, 256-character values, 50 tags). Those fail at apply time.

## Tag precedence

`tags` is `merge(base_tags, canonical_tags)`, so the four module-managed tags win over `base_tags`. Every other key passes through with its key and value unchanged, and keys are case-sensitive.

| Key in `base_tags` | Result in `tags` |
| --- | --- |
| `Environment`, `ManagedBy`, `Repository`, `Root` | Overridden: the value comes from `environment`, `managed_by`, `repository`, and `root`. |
| `environment` (any other casing) | Kept as a separate tag next to `Environment`. |
| Anything else (`Application`, `CostCenter`, `Owner`, ...) | Kept. |

```hcl
base_tags = { Environment = "prod", Owner = "hatan4ik" }
environment = "dev"
# tags => { Environment = "dev", Owner = "hatan4ik", ManagedBy = "terraform", Repository = "...", Root = "..." }
```

The override is silent. Keep the canonical keys out of `base_tags`.

## Usage patterns

| Example | What it shows |
| --- | --- |
| [`examples/minimal`](examples/minimal) | One name and the four canonical tags; nothing else set. |
| [`examples/platform-root`](examples/platform-root) | The live sandbox pattern: a default name, `additional_names` for neighbouring roots, and `base_tags` read from a shared `root-context.yaml`. |
| [`examples/multi-environment`](examples/multi-environment) | `for_each` over environments with a stricter `name_max_length` of 32. |

## Security model

- Inputs are validated, not trusted. Names and identifiers accept only a closed character set; the environment is a closed list; the repository is `owner/name`; tag keys and values cannot be blank. A wrong value fails at plan time with a message, never at apply time inside a provider.
- No credentials and no network. The module declares no provider and reads no data source, so it runs identically under any identity and cannot reach AWS.
- No secrets. Nothing in the module is sensitive, and it must not be given a secret: names and tags are visible in plans, state, and the AWS console.
- Names are bounded. The `name_max_length` precondition prevents an unexpectedly long name from being emitted, and the module never truncates.

## Testing

Every run is `command = plan` against a resource-less module, so no credentials exist to leak and nothing can be created.

| File | What it pins |
| --- | --- |
| `tests/golden_master.tftest.hcl` | The exact `name_prefix`, `names`, and `tags` of the three live sandbox roots (`sandbox-network`, `sandbox-platform`, `sandbox-workload`) and the resource names the roots derive from them. The compatibility proof. |
| `tests/validation.tftest.hcl` | Every variable validation, with accepted boundary values and rejected values through `expect_failures`. |
| `tests/outputs.tftest.hcl` | Default and additional names, empty and multi-key `additional_names`, the `name_max_length` precondition (`expect_failures = [output.names]`), tag precedence. |
| `examples/*/tests/` | Each example's outputs. |

There is **no integration suite**. The module creates no AWS resource, so there is nothing to apply and no account to test against; `integration.yml` and `tests/integration/` do not exist, and the pipeline needs no cloud credentials at all.

## Design principles

- Single responsibility. The module names and tags; it does not generate uniqueness, look up an account, or know a service's limits. Service modules own their own constraints.
- Open/closed. New names arrive as data: another `additional_names` key, another component, a stricter `name_max_length`. Nothing needs the module edited.
- Liskov substitution. `name_prefix` is `names.default`, and every name in `names` obeys the same rules, so a consumer written against one name works against any other.
- Interface segregation. Only four inputs are required; the rest default to safe values or to nothing.
- Dependency inversion. The module depends on plain values, not on how they were produced, and on nothing outside itself.

The rationale, the frozen-interface decision, what is out of scope, and what is deferred to v2 are in [docs/DESIGN.md](docs/DESIGN.md).

## Compatibility promise

Live Terraform roots derive every resource name from `name_prefix` and `names`, and their provider `default_tags` from `tags`. A change to any of those values for the same inputs would replace resources or rewrite tags across a platform. Therefore within v1:

- Every input keeps its name, type, default, and the set of values it accepts and rejects.
- Every output keeps its name and shape and returns the same value for the same inputs.
- New inputs and outputs may be added only if they are optional and leave every existing output unchanged.
- Upgrading from v0.1.0 changes only the pinned ref: [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md).

## Compatibility and scope

- Terraform `>= 1.7.0, < 2.0.0`. No providers.
- Not included, deliberately: random or unique suffixes, truncation, service-specific length or character rules, account and Region discovery, tag policy enforcement, and name templates. They stay in service modules and roots; see [docs/DESIGN.md](docs/DESIGN.md#out-of-scope-deliberately).

## Versioning and releases

Releases follow semantic versioning: incompatible interface changes bump the major version, new optional inputs and outputs bump the minor version, fixes bump the patch version. Every release is a signed annotated tag `vX.Y.Z`.

Pin the full commit SHA of the release tag and record the tag in a comment, so the source cannot move under you:

```hcl
module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=<commit-sha>" # v1.0.0
}
```

The `module-release` workflow publishes an immutable GitHub release only from a GitHub-verified, signed, annotated semantic-version tag that points at the merged `main` revision; lightweight or unsigned tags are rejected before anything is published. With a GitHub-associated GPG or SSH signing key configured:

```bash
git fetch origin
git tag -s vX.Y.Z <commit> -m "vX.Y.Z"
git push origin vX.Y.Z
gh workflow run module-release.yml --ref vX.Y.Z -f release_tag=vX.Y.Z
```

Dispatch from the tag, never from `main`: the workflow verifies that the tag points at the revision it checked out, and a maintenance release for an older line (for example a 0.1.x fix after 1.0.0 landed on `main`) is cut from that line's commit.

Upgrading from 0.1.0: read [docs/UPGRADE-1.0.md](docs/UPGRADE-1.0.md); only the pinned ref changes. All changes are listed in [CHANGELOG.md](CHANGELOG.md).

## Contributing

Development setup, the local quality gate, the test-first workflow, and the release process are described in [CONTRIBUTING.md](CONTRIBUTING.md). Security reports go through [SECURITY.md](SECURITY.md).

## License

Apache-2.0. See [LICENSE](LICENSE).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_names"></a> [additional\_names](#input\_additional\_names) | Additional deterministic names keyed by a stable logical identifier. Each value is a complete ordered component list. | `map(list(string))` | `{}` | no |
| <a name="input_base_tags"></a> [base\_tags](#input\_base\_tags) | Allocation and ownership tags supplied by the root, for example Application, CostCenter, and Owner. Keys and values must be non-empty. The canonical tags Environment, ManagedBy, Repository, and Root always take the module's values, so a base\_tags entry with one of those keys is overridden. | `map(string)` | `{}` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Canonical deployment environment used in names and tags. | `string` | n/a | yes |
| <a name="input_managed_by"></a> [managed\_by](#input\_managed\_by) | Canonical IaC ownership tag value. | `string` | `"terraform"` | no |
| <a name="input_name_components"></a> [name\_components](#input\_name\_components) | Ordered lowercase components used to derive the default deterministic name prefix. | `list(string)` | n/a | yes |
| <a name="input_name_max_length"></a> [name\_max\_length](#input\_name\_max\_length) | Maximum allowed length for every emitted name. Service modules remain responsible for stricter service-specific limits. | `number` | `63` | no |
| <a name="input_name_separator"></a> [name\_separator](#input\_name\_separator) | Separator used between deterministic name components. | `string` | `"-"` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Source repository in owner/name form. | `string` | n/a | yes |
| <a name="input_root"></a> [root](#input\_root) | Stable Terraform root identifier included in canonical tags. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name_prefix"></a> [name\_prefix](#output\_name\_prefix) | Default deterministic name derived from name\_components. |
| <a name="output_names"></a> [names](#output\_names) | Default and additional deterministic names keyed by logical identifier. |
| <a name="output_tags"></a> [tags](#output\_tags) | Canonical merged ownership, allocation, and provenance tags. |
<!-- END_TF_DOCS -->
