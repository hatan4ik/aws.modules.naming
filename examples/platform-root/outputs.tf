output "name_prefix" {
  description = "Default name of this root, from name_components."
  value       = module.naming.name_prefix
}

output "names" {
  description = "Default name plus the additional names of the neighbouring roots, keyed by logical identifier."
  value       = module.naming.names
}

output "tags" {
  description = "Canonical tags: the allocation tags from root-context.yaml plus Environment, ManagedBy, Repository, and Root."
  value       = module.naming.tags
}

output "platform_contract" {
  description = "Resource names and tags a platform root derives from the naming outputs."
  value       = terraform_data.platform_contract.input
}
