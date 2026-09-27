# Design: aws.modules.naming v1

Status: accepted 2026-09-27. Interface-compatible successor to v0.1.0; nothing is superseded.

## Purpose

`aws.modules.naming` turns a handful of validated inputs into three values that
a Terraform root derives everything else from:

- `name_prefix`: the default deterministic name, the components joined with `-`;
- `names`: the default name plus any number of additional names, each keyed by a
  stable logical identifier, all checked against a caller-chosen maximum length;
- `tags`: the caller's allocation tags merged with four canonical provenance
  tags (`Environment`, `ManagedBy`, `Repository`, `Root`).

It is pure and deterministic. It declares no provider, reads no data source,
creates no resource, and produces the same output for the same input on every
run, in every account and Region. That is the point of it: a resource name that
is a function of reviewed inputs is a name nobody has to look up and nothing can
drift.

## The frozen-interface decision

v1.0.0 is the first release that carries the "world-class" repository standard
(tests for every rule, examples, upgrade guide, quality pipeline) but it does
**not** change the module's interface. This is a deliberate decision, not an
omission, and it dominates every other choice below.

Three live Terraform roots call v0.1.0, pinned by SHA
(`c0fa6b65f35b1a3c11f64959a753af6bfe8e256e`), and derive **every** resource name
in the sandbox platform from it:

| Root | Inputs | Consumes |
| --- | --- | --- |
| `sandbox-network` | `root = "sandbox-network"`, components `sandbox-network-<env>` | `name_prefix` (VPC name), `tags` (VPC tags and the provider `default_tags`) |
| `sandbox-platform` | `root = "sandbox-platform"`, `additional_names` `network`, `workload` | `name_prefix` (ECS platform core), `names.network` (VPC lookup), `names.workload` (log group ARN), `tags` |
| `sandbox-workload` | `root = "sandbox-workload"`, `additional_names` `network`, `platform` | `name_prefix` (service), `names.network` and `names.platform` (VPC, cluster, KMS alias and DynamoDB table lookups), `tags` |

A change to the value of `name_prefix` or `names` for the same inputs would
rename an ECS cluster, a KMS alias, a DynamoDB table, a VPC and their log groups.
Most of those cannot be renamed in place, so Terraform would plan a replacement,
or a data lookup by name would stop finding the resource it points at. A change
to `tags` would rewrite the tags of every resource in every root through
`default_tags`. There is no `moved` block for a value that flows through a
string.

Therefore:

1. Every existing variable keeps its name, type, default, nullability and the
   set of values it accepts and rejects.
2. Every existing output keeps its name and shape, and returns the identical
   value for identical inputs. The type constructors matter: `names` and `tags`
   remain the same kinds of value as before, so `==` against an object or map
   literal in a consumer keeps its result.
3. Additions must be strictly additive and optional. v1.0.0 adds none: the
   variable and output lists are exactly those of v0.1.0.
4. Only diagnostics, descriptions and documentation may improve.
5. A consumer upgrades by changing the pinned ref and nothing else. No `moved`
   blocks and no state operations exist, because no resource address exists.

The rule is enforced, not merely stated. `tests/golden_master.tftest.hcl` pins
the exact `name_prefix`, `names` and `tags` of the three real platform calls,
built from their `main.tf` files and from `infra/active/root-context.yaml`. The
same file passes against the v0.1.0 code, which is how the expected values were
established (they were not derived from v1). Its failure messages say that a
change breaks live resource names, so a maintainer who sees one knows the
change is a major-version decision, not a test to update.

## What changed in v1.0.0

Every row leaves the output values untouched.

| Area | v0.1.0 | v1.0.0 |
| --- | --- | --- |
| A `null` element in `name_components`, in an `additional_names` list, or a `null` value in `base_tags` | The input was rejected, but by a raw `Invalid function argument` error from inside the validation expression, which no test can attribute to the variable. | Rejected by the variable's own validation, with its message. The accepted and rejected sets are unchanged. |
| `name_max_length` precondition message | "Every generated name must fit within name_max_length" and nothing else. | The same rule, and the message lists each offending name with its length and the limit. |
| `base_tags` description | "Required non-empty ... tags", although the default is `{}`. | Says what is true: optional, keys and values non-empty, canonical tags win on a clash. |
| Tests | One file, one run. | A golden master for the three live calls, every validation and precondition through `expect_failures`, tag precedence, and the `additional_names` edge cases. |
| Examples | None. | `minimal`, `platform-root`, `multi-environment`. |
| Repository | A hand-written workflow. | The shared `terraform-quality` and `module-release` workflows, Makefile gate, lint, security scan, docs drift check, upgrade guide, changelog. |

## Principles and how the module applies them

- **Single responsibility.** It names and tags, nothing else. Length limits of
  services, uniqueness suffixes, account and Region discovery all belong to
  someone else (see Out of scope).
- **Secure by default.** Names accept only lowercase letters, digits and hyphens;
  the environment is one of a closed list; the repository is `owner/name`; tag
  keys and values cannot be blank. A wrong value fails at plan time with a
  message, never at apply time inside a provider.
- **Deterministic.** No timestamps, no randomness, no map ordering dependence:
  `names` is keyed, and its values are pure functions of the component lists.
- **Fail rather than adapt.** A name that is too long is rejected, never
  truncated. Truncation would make two distinct components collide silently and
  make a name depend on its neighbours.
- **No providers, no data sources.** The module works offline and identically
  under any credentials.

## Architecture

```text
root (no resources)
├── variables.tf   Nine inputs, each validated at plan time.
├── locals.tf      name_component_sets, names, tags.
├── outputs.tf     name_prefix, names (with the length precondition), tags.
└── versions.tf    Terraform >= 1.7.0, < 2.0.0; no providers.
```

Data flow:

1. `name_component_sets` is `{ default = var.name_components }` merged with
   `var.additional_names`.
2. `names` joins each component list with `name_separator` (always `-`).
3. `name_prefix` is `names.default`.
4. `tags` is `base_tags` merged with the four canonical tags. `merge` lets the
   later argument win, so the canonical tags overwrite a same-named key in
   `base_tags`. This is current behaviour and it is kept and documented, not
   changed (see the README's tag precedence section).
5. The `names` output carries a `precondition`: every name must be at most
   `name_max_length` characters. A module without resources has no other object
   to attach the rule to, and an output precondition is evaluated whenever the
   module is, whichever output the caller reads.

### Naming contract

| Input | Accepts | Rejects |
| --- | --- | --- |
| `environment` | exactly one of `dev`, `staging`, `prod`, `shared`, `global`, `sandbox` | anything else |
| `root` | lowercase kebab-case: starts with a letter or digit, then letters, digits and hyphens, does not end with a hyphen | uppercase, spaces, underscores, empty, leading or trailing hyphen |
| `repository` | `owner/name`: two non-empty segments, one slash, no whitespace | no slash, more than one slash, whitespace, empty segments |
| `name_components` | one or more components, each lowercase kebab-case as for `root` | an empty list, and any bad or `null` component |
| `additional_names` | a map of identifier to component list; the key is `[a-z][a-z0-9_]*`, the list is non-empty and each component is valid as above | bad keys, empty lists, bad or `null` components, a `null` list |
| `name_separator` | `-` | any other value |
| `name_max_length` | a number from 1 to 128 (default 63) | outside that range |
| `base_tags` | a map of strings with non-blank keys and non-blank values | blank or `null` values, blank keys |
| `managed_by` | any non-blank string (default `terraform`) | blank |

## Testing strategy

- **Golden master** (`tests/golden_master.tftest.hcl`): the compatibility proof
  for the three live calls, as described above.
- **Validation** (`tests/validation.tftest.hcl`): every variable validation has
  passing boundary cases and failing cases through `expect_failures`.
- **Outputs** (`tests/outputs.tftest.hcl`): the default and additional names,
  empty and multi-key `additional_names`, tag precedence, the length
  precondition through `expect_failures = [output.names]` (supported by
  Terraform 1.7.5), and the exact-fit boundary.
- **Examples**: each example has a `tests/` file asserting its outputs, and CI
  runs the whole gate in every example directory.
- Everything is `command = plan` with no provider, so no credentials exist to
  leak and nothing can be created. There is no integration suite: the module
  creates no AWS resource and has nothing to apply.

## Compatibility

- Terraform `>= 1.7.0, < 2.0.0`, developed against 1.7.5, the version the
  consuming platform pins. No providers are required.
- Nothing in the v1 interface is scheduled to change before a v2.

## Out of scope, deliberately

- **Random or unique suffixes.** A random suffix makes a name a function of
  state, not of inputs, which defeats the module. Where a service needs global
  uniqueness (an S3 bucket), the service module or the root adds it.
- **Truncation or hashing.** Names are rejected when too long, never shortened.
  The caller shortens a component and reviews the result.
- **Service-specific length or character rules.** S3 buckets, IAM roles, target
  groups, load balancers and log groups each have their own limits. The service
  module owns its limit; the caller can set a stricter `name_max_length` to
  fail earlier.
- **Discovery of account, Region or partition.** Roots keep their explicit
  account, Region and backend inputs.
- **Tag policy.** The module guarantees the canonical tags and non-blank
  values. Organisation tag policy and the AWS limits on tag keys and values are
  not enforced here.
- **Name templates.** The order and meaning of components is the caller's
  decision; the module joins what it is given.

## Deferred to v2

Interface changes that would improve the module but cannot ship before a major
version, because each changes what some valid v0.1.0 input returns or whether it
is accepted. None affects the three live roots today.

1. **Reserve the `default` key in `additional_names`.** The merge lets an
   `additional_names` entry named `default` silently replace the component list
   that produces `name_prefix`. A validation should reject the key. It is
   pinned by a test as current behaviour so its removal is a conscious change.
2. **Reject or warn on canonical keys in `base_tags`.** A `base_tags` entry
   named `Environment`, `ManagedBy`, `Repository` or `Root` is overwritten
   silently. A validation would turn the silent override into an error.
3. **Validate tags against AWS limits.** Reject the reserved `aws:` prefix,
   keys over 128 and values over 256 characters, and more than 50 tags, so the
   failure moves from apply to plan.
4. **Retire `name_separator`.** It accepts only `-`, so it is a constant with an
   input's clothing. Either remove it or make a second separator a real choice.
5. **Split `default` out of `names`.** `names` contains the reserved key
   `default` next to the caller's keys, and `name_prefix` duplicates it. A
   clean shape is `name_prefix` plus a `names` holding only additional names,
   or a `map(string)` instead of an object. Both change the value consumers
   compare and iterate.
6. **Derive `Environment` into the name.** Today the environment appears in
   names only because the caller puts it in `name_components`. A module-owned
   layout would be safer and would change every name.

Relaxing the `environment` list (for example adding `test`) is additive and
could ship in a v1.x minor release; it is listed here so nobody mistakes it for
a breaking change.

## Migration

`docs/UPGRADE-1.0.md` shows that a consumer changes only the pinned ref: every
input and output is identical, there are no resources, so there is nothing to
move, and the plan shows no changes.
