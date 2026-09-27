variable "environment" {
  description = "Canonical deployment environment used in names and tags."
  type        = string
  nullable    = false

  validation {
    condition     = contains(["dev", "staging", "prod", "shared", "global", "sandbox"], var.environment)
    error_message = "environment must be one of dev, staging, prod, shared, global, or sandbox."
  }
}

variable "root" {
  description = "Stable Terraform root identifier included in canonical tags."
  type        = string
  nullable    = false

  validation {
    condition     = var.root == lower(trimspace(var.root)) && can(regex("^[a-z0-9][a-z0-9-]*$", var.root)) && !endswith(var.root, "-")
    error_message = "root must be a lowercase kebab-case identifier."
  }
}

variable "repository" {
  description = "Source repository in owner/name form."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[^/[:space:]]+/[^/[:space:]]+$", var.repository))
    error_message = "repository must be in owner/name form."
  }
}

variable "name_components" {
  description = "Ordered lowercase components used to derive the default deterministic name prefix."
  type        = list(string)
  nullable    = false

  validation {
    # `&&` does not short-circuit in Terraform 1.7, so a null component is
    # rejected with a conditional instead of failing inside trimspace().
    condition = length(var.name_components) > 0 && alltrue([
      for component in var.name_components :
      component == null ? false : (component == lower(trimspace(component)) && can(regex("^[a-z0-9][a-z0-9-]*$", component)) && !endswith(component, "-"))
    ])
    error_message = "name_components must contain one or more lowercase alphanumeric or hyphenated components."
  }
}

variable "additional_names" {
  description = "Additional deterministic names keyed by a stable logical identifier. Each value is a complete ordered component list."
  type        = map(list(string))
  default     = {}
  nullable    = false

  validation {
    # A null list or a null component is rejected with a conditional, because
    # `&&` does not short-circuit in Terraform 1.7.
    condition = alltrue([
      for name, components in var.additional_names :
      can(regex("^[a-z][a-z0-9_]*$", name)) && (
        components == null ? false : (
          length(components) > 0 && alltrue([
            for component in components :
            component == null ? false : (component == lower(trimspace(component)) && can(regex("^[a-z0-9][a-z0-9-]*$", component)) && !endswith(component, "-"))
          ])
        )
      )
    ])
    error_message = "additional_names keys must be identifiers and every name component must be lowercase alphanumeric or hyphenated."
  }
}

variable "name_separator" {
  description = "Separator used between deterministic name components."
  type        = string
  default     = "-"
  nullable    = false

  validation {
    condition     = var.name_separator == "-"
    error_message = "AWS platform names use a hyphen separator."
  }
}

variable "name_max_length" {
  description = "Maximum allowed length for every emitted name. Service modules remain responsible for stricter service-specific limits."
  type        = number
  default     = 63
  nullable    = false

  validation {
    condition     = var.name_max_length >= 1 && var.name_max_length <= 128
    error_message = "name_max_length must be between 1 and 128."
  }
}

variable "base_tags" {
  description = "Allocation and ownership tags supplied by the root, for example Application, CostCenter, and Owner. Keys and values must be non-empty. The canonical tags Environment, ManagedBy, Repository, and Root always take the module's values, so a base_tags entry with one of those keys is overridden."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    # A null value is rejected with a conditional, because `&&` does not
    # short-circuit in Terraform 1.7.
    condition     = alltrue([for key, value in var.base_tags : value == null ? false : (length(trimspace(key)) > 0 && length(trimspace(value)) > 0)])
    error_message = "base_tags must contain non-empty keys and values."
  }
}

variable "managed_by" {
  description = "Canonical IaC ownership tag value."
  type        = string
  default     = "terraform"
  nullable    = false

  validation {
    condition     = length(trimspace(var.managed_by)) > 0
    error_message = "managed_by must not be empty."
  }
}
