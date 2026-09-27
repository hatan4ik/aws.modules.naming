# Upgrading from 0.1.0 to 1.0.0

## What changed and why

Nothing that a consumer can observe in a value. Version 1.0.0 keeps every input and every output of 0.1.0 with the same name, type, default, and behaviour, and returns the identical `name_prefix`, `names`, and `tags` for the same inputs. It adds the test suite, examples, documentation, and quality pipeline of the other v1 modules, and improves two diagnostics.

The interface is frozen on purpose. Live Terraform roots derive every resource name from `name_prefix` and `names`, and their provider `default_tags` from `tags`; a different value would rename or retag real resources, and no `moved` block can express a value that flows through a string. The reasoning, and the changes that were considered and deferred to a v2, are in [DESIGN.md](DESIGN.md).

This guide moves a 0.1.0 consumer onto 1.0.0. The whole migration is one edit.

## Input and output mapping

Every row is unchanged.

| 0.1.0 input | Type | Default | 1.0.0 |
| --- | --- | --- | --- |
| `environment` | `string` | none | Unchanged. |
| `root` | `string` | none | Unchanged. |
| `repository` | `string` | none | Unchanged. |
| `name_components` | `list(string)` | none | Unchanged. |
| `additional_names` | `map(list(string))` | `{}` | Unchanged. |
| `name_separator` | `string` | `"-"` | Unchanged. |
| `name_max_length` | `number` | `63` | Unchanged. |
| `base_tags` | `map(string)` | `{}` | Unchanged. |
| `managed_by` | `string` | `"terraform"` | Unchanged. |

| 0.1.0 output | 1.0.0 |
| --- | --- |
| `name_prefix` | Unchanged. |
| `names` | Unchanged, including the `default` key and the length precondition. |
| `tags` | Unchanged, including that the canonical tags win over `base_tags`. |

There are no new inputs and no new outputs. Nothing that 0.1.0 accepted is rejected, and nothing it rejected is accepted.

## The one edit

Change the pinned ref. For the consumer block `module "naming"`:

```diff
 module "naming" {
-  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=c0fa6b65f35b1a3c11f64959a753af6bfe8e256e" # v0.1.0
+  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=<commit-sha>" # v1.0.0

   environment     = var.environment
   root            = "sandbox-platform"
   repository      = local.platform_context.repository
   name_components = ["sandbox", "platform", var.environment]
   # ... every other argument stays exactly as it is
 }
```

`<commit-sha>` is the full commit SHA of tag `v1.0.0`. Do not change any other argument, and do not rename the module block.

## What is different

Only text a person reads:

- A `null` component in `name_components` or in an `additional_names` list, or a `null` value in `base_tags`, was rejected in 0.1.0 by an `Invalid function argument` error from inside the validation expression. It is now rejected by the variable's own validation, with its message. It fails either way.
- The `name_max_length` precondition on `names` fails with the same rule as before and now also lists each offending name with its length.
- The description of `base_tags` says what is true: the input is optional and the canonical tags override a same-named key.

## State addresses

None change, because there are none. The module declares no resource, data source, or provider, so it contributes nothing to state and there is nothing to move, rename, import, or forget:

| 0.1.0 address | 1.0.0 address |
| --- | --- |
| (none) | (none) |

No `moved` blocks and no `terraform state` commands are needed.

## Procedure

1. Pin the 1.0.0 release: copy the commit SHA of tag `v1.0.0` into `?ref=<commit-sha>` and put the tag in a trailing comment.
2. Run `terraform init -upgrade` to fetch the new module source.
3. Run `terraform plan`.
4. Verify the plan is empty: `No changes. Your infrastructure matches the configuration.` A module output value is not a resource, so nothing can be replaced by this upgrade. If the plan shows any change to a resource name, a lookup, or a tag, stop and do not apply: the value of an output moved, which 1.0.0 does not do. Report it as a bug with your module call.
5. Nothing needs applying. Commit the new ref.

## Checking your own call

`tests/golden_master.tftest.hcl` pins the outputs of the three live sandbox roots and is the model for your own. To pin yours, copy one `run` block, put your inputs in `variables`, and assert the `name_prefix`, `names`, and `tags` you get today from 0.1.0. Run it against the 0.1.0 code first, then against 1.0.0; both must pass.
