# Every variable validation, with accepted boundary values and rejected values.
# A rejected value is asserted with expect_failures against the variable that
# carries the rule, so the run passes only if exactly that validation fails.
# No provider is involved; every run is a plan of a resource-less module.

variables {
  environment     = "dev"
  root            = "sandbox-platform"
  repository      = "hatan4ik/devops-aws-infra"
  name_components = ["sandbox", "platform", "dev"]
}

# ---------------------------------------------------------------- environment

run "environment_accepts_dev" {
  command = plan
  variables { environment = "dev" }
  assert {
    condition     = output.tags.Environment == "dev"
    error_message = "environment dev must be accepted and tagged."
  }
}

run "environment_accepts_staging" {
  command = plan
  variables { environment = "staging" }
  assert {
    condition     = output.tags.Environment == "staging"
    error_message = "environment staging must be accepted and tagged."
  }
}

run "environment_accepts_prod" {
  command = plan
  variables { environment = "prod" }
  assert {
    condition     = output.tags.Environment == "prod"
    error_message = "environment prod must be accepted and tagged."
  }
}

run "environment_accepts_shared" {
  command = plan
  variables { environment = "shared" }
  assert {
    condition     = output.tags.Environment == "shared"
    error_message = "environment shared must be accepted and tagged."
  }
}

run "environment_accepts_global" {
  command = plan
  variables { environment = "global" }
  assert {
    condition     = output.tags.Environment == "global"
    error_message = "environment global must be accepted and tagged."
  }
}

run "environment_accepts_sandbox" {
  command = plan
  variables { environment = "sandbox" }
  assert {
    condition     = output.tags.Environment == "sandbox"
    error_message = "environment sandbox must be accepted and tagged."
  }
}

run "environment_rejects_unknown_value" {
  command = plan
  variables { environment = "test" }
  expect_failures = [var.environment]
}

run "environment_rejects_wrong_case" {
  command = plan
  variables { environment = "Dev" }
  expect_failures = [var.environment]
}

run "environment_rejects_surrounding_whitespace" {
  command = plan
  variables { environment = " dev" }
  expect_failures = [var.environment]
}

run "environment_rejects_empty" {
  command = plan
  variables { environment = "" }
  expect_failures = [var.environment]
}

# ----------------------------------------------------------------------- root

run "root_accepts_single_character" {
  command = plan
  variables { root = "a" }
  assert {
    condition     = output.tags.Root == "a"
    error_message = "A one-character root must be accepted."
  }
}

run "root_accepts_leading_digit_and_inner_hyphens" {
  command = plan
  variables { root = "0-a--b-9" }
  assert {
    condition     = output.tags.Root == "0-a--b-9"
    error_message = "A root may start with a digit and contain hyphens, including consecutive ones."
  }
}

run "root_rejects_empty" {
  command = plan
  variables { root = "" }
  expect_failures = [var.root]
}

run "root_rejects_uppercase" {
  command = plan
  variables { root = "Sandbox-platform" }
  expect_failures = [var.root]
}

run "root_rejects_leading_hyphen" {
  command = plan
  variables { root = "-sandbox" }
  expect_failures = [var.root]
}

run "root_rejects_trailing_hyphen" {
  command = plan
  variables { root = "sandbox-" }
  expect_failures = [var.root]
}

run "root_rejects_underscore" {
  command = plan
  variables { root = "sandbox_platform" }
  expect_failures = [var.root]
}

run "root_rejects_inner_space" {
  command = plan
  variables { root = "sandbox platform" }
  expect_failures = [var.root]
}

run "root_rejects_surrounding_whitespace" {
  command = plan
  variables { root = " sandbox" }
  expect_failures = [var.root]
}

# ----------------------------------------------------------------- repository

run "repository_accepts_owner_and_name" {
  command = plan
  variables { repository = "a/b" }
  assert {
    condition     = output.tags.Repository == "a/b"
    error_message = "The shortest owner/name must be accepted."
  }
}

run "repository_accepts_dots_underscores_and_uppercase" {
  command = plan
  variables { repository = "My-Org/repo.name_1" }
  assert {
    condition     = output.tags.Repository == "My-Org/repo.name_1"
    error_message = "Only the slash and whitespace are constrained; other characters are accepted as given."
  }
}

run "repository_rejects_empty" {
  command = plan
  variables { repository = "" }
  expect_failures = [var.repository]
}

run "repository_rejects_missing_slash" {
  command = plan
  variables { repository = "devops-aws-infra" }
  expect_failures = [var.repository]
}

run "repository_rejects_extra_segment" {
  command = plan
  variables { repository = "hatan4ik/devops/aws-infra" }
  expect_failures = [var.repository]
}

run "repository_rejects_empty_owner" {
  command = plan
  variables { repository = "/devops-aws-infra" }
  expect_failures = [var.repository]
}

run "repository_rejects_empty_name" {
  command = plan
  variables { repository = "hatan4ik/" }
  expect_failures = [var.repository]
}

run "repository_rejects_whitespace_in_owner" {
  command = plan
  variables { repository = "hatan4ik /devops-aws-infra" }
  expect_failures = [var.repository]
}

run "repository_rejects_whitespace_in_name" {
  command = plan
  variables { repository = "hatan4ik/devops aws-infra" }
  expect_failures = [var.repository]
}

# ------------------------------------------------------------ name_components

run "name_components_accepts_one_component" {
  command = plan
  variables { name_components = ["a"] }
  assert {
    condition     = output.name_prefix == "a"
    error_message = "A single component must be accepted and emitted unchanged."
  }
}

run "name_components_accepts_digits_and_inner_hyphens" {
  command = plan
  variables { name_components = ["0a", "b-c", "d--e", "9"] }
  assert {
    condition     = output.name_prefix == "0a-b-c-d--e-9"
    error_message = "Components may start with a digit and contain hyphens; the module only joins them."
  }
}

run "name_components_rejects_empty_list" {
  command = plan
  variables { name_components = [] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_empty_component" {
  command = plan
  variables { name_components = ["sandbox", ""] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_uppercase" {
  command = plan
  variables { name_components = ["sandbox", "Platform"] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_leading_hyphen" {
  command = plan
  variables { name_components = ["-sandbox"] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_trailing_hyphen" {
  command = plan
  variables { name_components = ["sandbox-", "platform"] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_underscore" {
  command = plan
  variables { name_components = ["sandbox_platform"] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_whitespace" {
  command = plan
  variables { name_components = ["sandbox", "plat form"] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_surrounding_whitespace" {
  command = plan
  variables { name_components = ["sandbox ", "platform"] }
  expect_failures = [var.name_components]
}

run "name_components_rejects_null_component" {
  command = plan
  variables { name_components = ["sandbox", null] }
  expect_failures = [var.name_components]
}

# ---------------------------------------------------------- additional_names

run "additional_names_accepts_empty_map" {
  command = plan
  variables { additional_names = {} }
  assert {
    condition     = output.names == { default = "sandbox-platform-dev" }
    error_message = "An empty additional_names must leave only the default name."
  }
}

run "additional_names_accepts_identifier_keys" {
  command = plan
  variables {
    additional_names = {
      a          = ["x"]
      network_v2 = ["y", "z-1"]
    }
  }
  assert {
    condition     = output.names.a == "x" && output.names.network_v2 == "y-z-1"
    error_message = "Keys start with a lowercase letter and may contain digits and underscores."
  }
}

run "additional_names_rejects_uppercase_key" {
  command = plan
  variables { additional_names = { Network = ["sandbox", "network"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_key_starting_with_digit" {
  command = plan
  variables { additional_names = { "1network" = ["sandbox", "network"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_hyphen_in_key" {
  command = plan
  variables { additional_names = { "net-work" = ["sandbox", "network"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_underscore_leading_key" {
  command = plan
  variables { additional_names = { "_network" = ["sandbox", "network"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_empty_key" {
  command = plan
  variables { additional_names = { "" = ["sandbox", "network"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_empty_component_list" {
  command = plan
  variables { additional_names = { network = [] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_uppercase_component" {
  command = plan
  variables { additional_names = { network = ["sandbox", "Network"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_trailing_hyphen_component" {
  command = plan
  variables { additional_names = { network = ["sandbox-"] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_empty_component" {
  command = plan
  variables { additional_names = { network = ["sandbox", ""] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_null_component" {
  command = plan
  variables { additional_names = { network = ["sandbox", null] } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_null_list" {
  command = plan
  variables { additional_names = { network = null } }
  expect_failures = [var.additional_names]
}

run "additional_names_rejects_one_bad_entry_among_good_ones" {
  command = plan
  variables {
    additional_names = {
      network  = ["sandbox", "network"]
      workload = ["Sandbox", "workload"]
    }
  }
  expect_failures = [var.additional_names]
}

# ------------------------------------------------------------- name_separator

run "name_separator_accepts_hyphen" {
  command = plan
  variables { name_separator = "-" }
  assert {
    condition     = output.name_prefix == "sandbox-platform-dev"
    error_message = "The hyphen separator must be accepted."
  }
}

run "name_separator_rejects_underscore" {
  command = plan
  variables { name_separator = "_" }
  expect_failures = [var.name_separator]
}

run "name_separator_rejects_dot" {
  command = plan
  variables { name_separator = "." }
  expect_failures = [var.name_separator]
}

run "name_separator_rejects_empty" {
  command = plan
  variables { name_separator = "" }
  expect_failures = [var.name_separator]
}

run "name_separator_rejects_doubled_hyphen" {
  command = plan
  variables { name_separator = "--" }
  expect_failures = [var.name_separator]
}

# ------------------------------------------------------------ name_max_length

run "name_max_length_accepts_lower_bound" {
  command = plan
  variables {
    name_components = ["a"]
    name_max_length = 1
  }
  assert {
    condition     = output.name_prefix == "a"
    error_message = "name_max_length 1 must be accepted when the name fits."
  }
}

run "name_max_length_accepts_upper_bound" {
  command = plan
  variables { name_max_length = 128 }
  assert {
    condition     = output.name_prefix == "sandbox-platform-dev"
    error_message = "name_max_length 128 must be accepted."
  }
}

run "name_max_length_rejects_zero" {
  command = plan
  variables { name_max_length = 0 }
  expect_failures = [var.name_max_length]
}

run "name_max_length_rejects_negative" {
  command = plan
  variables { name_max_length = -1 }
  expect_failures = [var.name_max_length]
}

run "name_max_length_rejects_above_upper_bound" {
  command = plan
  variables { name_max_length = 129 }
  expect_failures = [var.name_max_length]
}

# ------------------------------------------------------------------ base_tags

run "base_tags_accepts_empty_map" {
  command = plan
  variables { base_tags = {} }
  assert {
    condition     = length(output.tags) == 4
    error_message = "Empty base_tags must leave exactly the four canonical tags."
  }
}

run "base_tags_accepts_non_blank_pairs" {
  command = plan
  variables { base_tags = { CostCenter = "platform-bootstrap", "team name" = "a b" } }
  assert {
    condition     = output.tags["team name"] == "a b" && output.tags.CostCenter == "platform-bootstrap"
    error_message = "Non-blank keys and values are accepted as given, including inner spaces."
  }
}

run "base_tags_rejects_empty_value" {
  command = plan
  variables { base_tags = { Owner = "" } }
  expect_failures = [var.base_tags]
}

run "base_tags_rejects_whitespace_value" {
  command = plan
  variables { base_tags = { Owner = "   " } }
  expect_failures = [var.base_tags]
}

run "base_tags_rejects_empty_key" {
  command = plan
  variables { base_tags = { "" = "platform" } }
  expect_failures = [var.base_tags]
}

run "base_tags_rejects_whitespace_key" {
  command = plan
  variables { base_tags = { "  " = "platform" } }
  expect_failures = [var.base_tags]
}

run "base_tags_rejects_null_value" {
  command = plan
  variables { base_tags = { Owner = null } }
  expect_failures = [var.base_tags]
}

# ------------------------------------------------------------------ managed_by

run "managed_by_accepts_another_tool" {
  command = plan
  variables { managed_by = "opentofu" }
  assert {
    condition     = output.tags.ManagedBy == "opentofu"
    error_message = "managed_by must be emitted as given."
  }
}

run "managed_by_rejects_empty" {
  command = plan
  variables { managed_by = "" }
  expect_failures = [var.managed_by]
}

run "managed_by_rejects_whitespace" {
  command = plan
  variables { managed_by = "  " }
  expect_failures = [var.managed_by]
}
