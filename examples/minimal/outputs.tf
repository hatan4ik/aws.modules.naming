output "name" {
  description = "Deterministic name for the application in this environment: the components joined with hyphens."
  value       = module.naming.name_prefix
}

output "tags" {
  description = "Canonical tags for the root: the four provenance tags Environment, ManagedBy, Repository, and Root."
  value       = module.naming.tags
}
