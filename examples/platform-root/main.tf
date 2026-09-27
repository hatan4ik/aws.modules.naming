locals {
  # The platform context is read once and shared. base_tags is a YAML mapping;
  # tomap() gives the module the map(string) it declares.
  platform_context = yamldecode(file("${path.module}/root-context.yaml"))
}

# The sandbox-platform call: a default name for this root and one additional
# name for each neighbouring root it must refer to.
module "naming" {
  source = "../../"

  environment     = var.environment
  root            = "sandbox-platform"
  repository      = local.platform_context.repository
  name_components = ["sandbox", "platform", var.environment]

  additional_names = {
    network  = ["sandbox", "network", var.environment]
    workload = ["sandbox", "workload", var.environment]
  }

  base_tags = tomap(local.platform_context.base_tags)
}

# Every resource name in the platform is a pure function of the naming outputs.
# That is why the module's interface is frozen: a change to name_prefix or names
# would rename the resources and lookups built from them. terraform_data stands
# in for the real resources so the example needs no provider.
resource "terraform_data" "platform_contract" {
  input = {
    cluster_name       = "${module.naming.name_prefix}-cluster"
    network_lookup     = module.naming.names.network
    workload_log_group = "/aws/ecs/${module.naming.names.workload}"
    default_tags       = module.naming.tags
  }
}
