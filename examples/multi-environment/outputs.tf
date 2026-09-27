output "name_prefixes" {
  description = "Default name of the application in each environment, keyed by environment."
  value       = { for environment, naming in module.naming : environment => naming.name_prefix }
}

output "names" {
  description = "All names in each environment, keyed by environment and then by logical identifier."
  value       = { for environment, naming in module.naming : environment => naming.names }
}

output "tags" {
  description = "Canonical tags in each environment, keyed by environment."
  value       = { for environment, naming in module.naming : environment => naming.tags }
}
