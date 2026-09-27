# Behaviour of the three outputs: names, the length precondition on `names`,
# and tag precedence. Input rules live in validation.tftest.hcl; the values the
# live platform roots receive live in golden_master.tftest.hcl.

variables {
  environment = "dev"
  root        = "sandbox-platform"
  repository  = "hatan4ik/devops-aws-infra"

  name_components = ["sandbox", "platform", "dev"]
  additional_names = {
    network = ["sandbox", "network", "dev"]
  }

  base_tags = {
    Application = "platform"
    CostCenter  = "platform-bootstrap"
    Owner       = "hatan4ik"
  }
}

# ----------------------------------------------------------------------- names

run "derives_stable_names_and_tags" {
  command = plan

  assert {
    condition     = output.name_prefix == "sandbox-platform-dev"
    error_message = "The default platform name must be deterministic."
  }

  assert {
    condition     = output.names.network == "sandbox-network-dev"
    error_message = "Related resource names must be emitted explicitly."
  }

  assert {
    condition = output.tags == {
      Application = "platform"
      CostCenter  = "platform-bootstrap"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "hatan4ik"
      Repository  = "hatan4ik/devops-aws-infra"
      Root        = "sandbox-platform"
    }
    error_message = "The canonical tag contract must retain allocation tags and add provenance."
  }
}

run "name_prefix_is_the_default_name" {
  command = plan

  assert {
    condition     = output.name_prefix == output.names.default
    error_message = "name_prefix must be exactly names.default."
  }
}

run "empty_additional_names_leaves_only_the_default_name" {
  command = plan

  variables {
    additional_names = {}
  }

  assert {
    condition     = output.names == { default = "sandbox-platform-dev" }
    error_message = "With no additional names, names must contain exactly the default key."
  }
}

run "omitted_additional_names_behaves_like_empty" {
  command = plan

  variables {
    additional_names = null
  }

  assert {
    condition     = output.names == { default = "sandbox-platform-dev" }
    error_message = "A null additional_names falls back to the empty default."
  }
}

run "multiple_additional_names_are_all_emitted" {
  command = plan

  variables {
    additional_names = {
      workload   = ["sandbox", "workload", "dev"]
      network    = ["sandbox", "network", "dev"]
      data_store = ["sandbox", "data-store", "dev"]
    }
  }

  assert {
    condition = output.names == {
      default    = "sandbox-platform-dev"
      network    = "sandbox-network-dev"
      workload   = "sandbox-workload-dev"
      data_store = "sandbox-data-store-dev"
    }
    error_message = "Every additional name must be emitted under its key next to the default, and the default must be unaffected."
  }

  assert {
    condition     = output.name_prefix == "sandbox-platform-dev"
    error_message = "Additional names must not change name_prefix."
  }
}

run "additional_names_are_independent_of_the_default_components" {
  command = plan

  variables {
    name_components = ["other"]
    additional_names = {
      network = ["sandbox", "network"]
    }
  }

  assert {
    condition     = output.names.network == "sandbox-network" && output.name_prefix == "other"
    error_message = "Each additional name is a complete component list; it does not inherit the default components."
  }
}

run "components_are_joined_with_a_hyphen_without_normalising" {
  command = plan

  variables {
    name_components  = ["a--b", "c-d", "9"]
    additional_names = {}
  }

  assert {
    condition     = output.name_prefix == "a--b-c-d-9"
    error_message = "Components are joined verbatim; inner hyphens are kept."
  }
}

# Current behaviour, deliberately kept for v1 and listed under "Deferred to v2"
# in docs/DESIGN.md: an additional_names entry named `default` replaces the
# component list that produces name_prefix, because the maps are merged with
# additional_names last. Changing this changes what a valid v0.1.0 input returns.
run "additional_names_default_key_replaces_the_default_name" {
  command = plan

  variables {
    additional_names = {
      default = ["replaced", "prefix"]
    }
  }

  assert {
    condition     = output.name_prefix == "replaced-prefix" && output.names == { default = "replaced-prefix" }
    error_message = "Documented v1 behaviour: an additional_names key `default` overrides the default name. Removing it is a v2 interface change."
  }
}

# ---------------------------------------------------------- name_max_length

run "default_max_length_accepts_a_63_character_name" {
  command = plan

  variables {
    name_components  = [join("", [for i in range(63) : "a"])]
    additional_names = {}
  }

  assert {
    condition     = length(output.name_prefix) == 63
    error_message = "A name of exactly 63 characters fits the default name_max_length."
  }
}

run "default_max_length_rejects_a_64_character_name" {
  command = plan

  variables {
    name_components  = [join("", [for i in range(64) : "a"])]
    additional_names = {}
  }

  expect_failures = [output.names]
}

run "custom_max_length_accepts_a_name_of_exactly_that_length" {
  command = plan

  variables {
    name_max_length = 20
    additional_names = {
      network = ["sandbox", "network", "dev"]
    }
  }

  assert {
    condition     = length(output.name_prefix) == 20 && length(output.names.network) == 19
    error_message = "A name whose length equals name_max_length must be accepted."
  }
}

run "custom_max_length_rejects_a_default_name_one_character_too_long" {
  command = plan

  variables {
    name_max_length  = 19
    additional_names = {}
  }

  expect_failures = [output.names]
}

run "max_length_rejects_a_long_additional_name_when_the_default_fits" {
  command = plan

  variables {
    name_max_length = 20
    additional_names = {
      long_one = ["sandbox", "a-very-long-component", "dev"]
    }
  }

  expect_failures = [output.names]
}

run "max_length_is_checked_for_every_name_not_just_the_first" {
  command = plan

  variables {
    name_max_length = 22
    additional_names = {
      short = ["a"]
      fits  = ["sandbox", "network", "dev"]
      long  = ["sandbox", "workload", "dev", "extra"]
    }
  }

  expect_failures = [output.names]
}

run "names_are_never_truncated" {
  command = plan

  variables {
    name_max_length  = 128
    name_components  = [join("", [for i in range(100) : "b"])]
    additional_names = {}
  }

  assert {
    condition     = length(output.name_prefix) == 100
    error_message = "Names within name_max_length are emitted whole, never truncated."
  }
}

# ------------------------------------------------------------ tag precedence

run "tags_without_base_tags_are_exactly_the_canonical_four" {
  command = plan

  variables {
    base_tags = {}
  }

  assert {
    condition = output.tags == {
      Environment = "dev"
      ManagedBy   = "terraform"
      Repository  = "hatan4ik/devops-aws-infra"
      Root        = "sandbox-platform"
    }
    error_message = "Without base_tags the tag map is exactly Environment, ManagedBy, Repository, and Root."
  }
}

run "omitted_base_tags_behaves_like_empty" {
  command = plan

  variables {
    base_tags = null
  }

  assert {
    condition     = length(output.tags) == 4
    error_message = "A null base_tags falls back to the empty default."
  }
}

# Tag precedence, current behaviour kept in v1 and documented in the README:
# the module-managed tags win over base_tags because they are merged last.
run "canonical_tags_override_base_tags" {
  command = plan

  variables {
    base_tags = {
      Environment = "spoofed-environment"
      ManagedBy   = "spoofed-manager"
      Repository  = "spoofed/repository"
      Root        = "spoofed-root"
      Owner       = "hatan4ik"
    }
  }

  assert {
    condition = output.tags == {
      Environment = "dev"
      ManagedBy   = "terraform"
      Repository  = "hatan4ik/devops-aws-infra"
      Root        = "sandbox-platform"
      Owner       = "hatan4ik"
    }
    error_message = "Environment, ManagedBy, Repository, and Root must always carry the module's values; other base_tags are kept."
  }
}

run "managed_by_input_wins_over_a_base_tags_entry" {
  command = plan

  variables {
    managed_by = "opentofu"
    base_tags = {
      ManagedBy = "manual"
    }
  }

  assert {
    condition     = output.tags.ManagedBy == "opentofu"
    error_message = "The managed_by input, not base_tags, decides the ManagedBy tag."
  }
}

run "tag_keys_are_case_sensitive" {
  command = plan

  variables {
    base_tags = {
      environment = "lowercase-key"
    }
  }

  assert {
    condition     = output.tags.environment == "lowercase-key" && output.tags.Environment == "dev"
    error_message = "Only the exact canonical keys are overridden; a differently cased key is an ordinary base tag."
  }
}

run "base_tags_are_emitted_unchanged" {
  command = plan

  variables {
    base_tags = {
      Application = "platform"
      "team name" = "a b"
    }
  }

  assert {
    condition     = output.tags.Application == "platform" && output.tags["team name"] == "a b"
    error_message = "Allocation tags pass through with their keys and values unchanged."
  }
}
