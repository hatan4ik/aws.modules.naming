# AWS Terraform naming and tags

`aws.modules.naming` emits deterministic, validated name prefixes and a
canonical AWS tag map. It has no provider configuration and creates no cloud
resources.

## Contract

- Roots retain their explicit account, Region, backend, and security-boundary
  inputs; this module does not discover or weaken those contracts.
- Names are constructed from validated lowercase components. They are rejected
  when they exceed the caller-selected maximum instead of being silently
  truncated.
- Canonical provenance tags (`Environment`, `ManagedBy`, `Repository`, and
  `Root`) are merged with required allocation tags supplied by the root.
- Service modules own service-specific name constraints; callers can set a
  stricter `name_max_length`.

## Usage

~~~hcl
module "naming" {
  source = "git::https://github.com/hatan4ik/aws.modules.naming.git?ref=v0.1.0"

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
    Owner       = "platform-team"
  }
}
~~~

Use `module.naming.name_prefix`, `module.naming.names`, and
`module.naming.tags` in a root or service module. The repository CI runs
formatting, validation, and Terraform tests without cloud credentials.
