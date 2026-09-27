locals {
  # The default component list is the first argument and additional_names the
  # last. merge() lets a later argument win, so an additional_names key named
  # `default` replaces the default name. That is v0.1.0 behaviour and it is
  # kept; see "Deferred to v2" in docs/DESIGN.md.
  name_component_sets = merge(
    { default = var.name_components },
    var.additional_names,
  )

  names = {
    for name, components in local.name_component_sets :
    name => join(var.name_separator, components)
  }

  # The canonical tags are the last argument, so they win over a same-named key
  # in base_tags. That is v0.1.0 behaviour and it is kept; see the tag
  # precedence section of the README.
  tags = merge(var.base_tags, {
    Environment = var.environment
    ManagedBy   = var.managed_by
    Repository  = var.repository
    Root        = var.root
  })
}
