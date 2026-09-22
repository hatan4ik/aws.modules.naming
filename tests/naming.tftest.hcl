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
