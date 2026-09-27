# Platform root

The pattern the live sandbox roots use: one call per Terraform root that
derives the root's own name, the names of the roots it refers to, and the
canonical tags. This is the `sandbox-platform` call.

- `name_components` produces `name_prefix` (`sandbox-platform-dev`), the name of
  this root's resources.
- `additional_names` produces `names.network` and `names.workload`, the names
  of the neighbouring roots, without repeating the naming rule in each root.
- `base_tags` comes from `root-context.yaml`, a reviewed, non-secret file shared
  by every root. It is a YAML mapping, so the call converts it with `tomap()`.
- `terraform_data.platform_contract` stands in for the real resources: a
  cluster name, a lookup name and a log group path built from the outputs, and
  the tags a provider would take as `default_tags`. Every name in the platform
  is derived this way, which is why the module's interface is frozen. See
  [docs/DESIGN.md](../../docs/DESIGN.md).

## Run

```sh
terraform init
terraform plan -var environment=dev
```

`terraform test` runs the assertions in `tests/example.tftest.hcl`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_naming"></a> [naming](#module\_naming) | ../../ | n/a |

## Resources

| Name | Type |
|------|------|
| [terraform_data.platform_contract](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment of this root: dev, staging, prod, shared, global, or sandbox. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name_prefix"></a> [name\_prefix](#output\_name\_prefix) | Default name of this root, from name\_components. |
| <a name="output_names"></a> [names](#output\_names) | Default name plus the additional names of the neighbouring roots, keyed by logical identifier. |
| <a name="output_platform_contract"></a> [platform\_contract](#output\_platform\_contract) | Resource names and tags a platform root derives from the naming outputs. |
| <a name="output_tags"></a> [tags](#output\_tags) | Canonical tags: the allocation tags from root-context.yaml plus Environment, ManagedBy, Repository, and Root. |
<!-- END_TF_DOCS -->
