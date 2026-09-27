# Minimal naming

The smallest working call of `aws.modules.naming`: one name and the canonical
tags. The name is the application and the environment joined with a hyphen, and
the tags are the four provenance tags the module always emits (`Environment`,
`ManagedBy`, `Repository`, `Root`). Nothing else is set, so `additional_names`
is empty, `base_tags` is empty, and the name may be up to 63 characters.

The module creates no resource and needs no provider or credentials; the
outputs are the whole result. Use `module.naming.name_prefix` for resource
names and `module.naming.tags` for tags or a provider's `default_tags`.

## Run

```sh
terraform init
terraform plan \
  -var environment=prod \
  -var root=payments-api \
  -var repository=acme/infrastructure \
  -var application=payments
```

`terraform test` runs the assertions in `tests/example.tftest.hcl`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_naming"></a> [naming](#module\_naming) | ../../ | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Application component of the name, in lowercase kebab-case, such as payments. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment: dev, staging, prod, shared, global, or sandbox. | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | Source repository of the root in owner/name form, such as acme/infrastructure. | `string` | n/a | yes |
| <a name="input_root"></a> [root](#input\_root) | Identifier of the Terraform root that calls the module, in lowercase kebab-case, such as payments-api. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name"></a> [name](#output\_name) | Deterministic name for the application in this environment: the components joined with hyphens. |
| <a name="output_tags"></a> [tags](#output\_tags) | Canonical tags for the root: the four provenance tags Environment, ManagedBy, Repository, and Root. |
<!-- END_TF_DOCS -->
