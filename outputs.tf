output "name_prefix" {
  description = "Default deterministic name derived from name_components."
  value       = local.names.default
}

output "names" {
  description = "Default and additional deterministic names keyed by logical identifier."
  value       = local.names

  precondition {
    condition     = alltrue([for name in values(local.names) : length(name) <= var.name_max_length])
    error_message = "Every generated name must fit within name_max_length (${var.name_max_length}); do not silently truncate names. Too long: ${join(", ", [for key, name in local.names : "${key}=${name} (${length(name)})" if length(name) > var.name_max_length])}."
  }
}

output "tags" {
  description = "Canonical merged ownership, allocation, and provenance tags."
  value       = local.tags
}
