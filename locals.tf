locals {
  name_component_sets = merge(
    { default = var.name_components },
    var.additional_names,
  )

  names = {
    for name, components in local.name_component_sets :
    name => join(var.name_separator, components)
  }

  tags = merge(var.base_tags, {
    Environment = var.environment
    ManagedBy   = var.managed_by
    Repository  = var.repository
    Root        = var.root
  })
}
