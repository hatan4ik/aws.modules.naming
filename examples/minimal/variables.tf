variable "environment" {
  description = "Deployment environment: dev, staging, prod, shared, global, or sandbox."
  type        = string
}

variable "root" {
  description = "Identifier of the Terraform root that calls the module, in lowercase kebab-case, such as payments-api."
  type        = string
}

variable "repository" {
  description = "Source repository of the root in owner/name form, such as acme/infrastructure."
  type        = string
}

variable "application" {
  description = "Application component of the name, in lowercase kebab-case, such as payments."
  type        = string
}
