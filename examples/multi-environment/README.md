# Multiple environments

`for_each` over a set of environments, one module call each. The module holds no
state and creates nothing, so the calls are independent: every environment gets
its own default name, its `database` name and its tags from one declaration.

`name_max_length = 32` is stricter than the default of 63. Application and
network load balancers and target groups accept at most 32 characters, so the
call fails at plan time, naming the offending name, instead of at apply time
inside the provider. The module rejects a name that is too long and never
truncates it.

An environment outside `dev`, `staging`, `prod`, `shared`, `global`, and
`sandbox` is rejected by the module's own validation.

## Run

```sh
terraform init
terraform plan \
  -var 'environments=["dev","staging","prod"]' \
  -var root=payments-api \
  -var repository=acme/infrastructure \
  -var application=payments \
  -var owner=payments-team
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
| <a name="input_application"></a> [application](#input\_application) | Application component of every name, in lowercase kebab-case, such as payments. | `string` | n/a | yes |
| <a name="input_environments"></a> [environments](#input\_environments) | Environments to name, each one of dev, staging, prod, shared, global, or sandbox. | `set(string)` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Value of the Owner allocation tag. | `string` | n/a | yes |
| <a name="input_repository"></a> [repository](#input\_repository) | Source repository of the root in owner/name form, such as acme/infrastructure. | `string` | n/a | yes |
| <a name="input_root"></a> [root](#input\_root) | Identifier of the Terraform root that calls the module, in lowercase kebab-case, such as payments-api. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_name_prefixes"></a> [name\_prefixes](#output\_name\_prefixes) | Default name of the application in each environment, keyed by environment. |
| <a name="output_names"></a> [names](#output\_names) | All names in each environment, keyed by environment and then by logical identifier. |
| <a name="output_tags"></a> [tags](#output\_tags) | Canonical tags in each environment, keyed by environment. |
<!-- END_TF_DOCS -->
