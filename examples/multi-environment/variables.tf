variable "environments" {
  description = "Environments to name, each one of dev, staging, prod, shared, global, or sandbox."
  type        = set(string)
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
  description = "Application component of every name, in lowercase kebab-case, such as payments."
  type        = string
}

variable "owner" {
  description = "Value of the Owner allocation tag."
  type        = string
}
