# Golden master: the exact name_prefix, names and tags that the three live
# Terraform roots receive from aws.modules.naming v0.1.0.
#
#   infra/active/roots/sandbox-network/us-east-2/dev/main.tf
#   infra/active/roots/sandbox-platform/us-east-2/dev/main.tf
#   infra/active/roots/sandbox-workload/us-east-2/dev/main.tf
#
# Each root passes environment "dev", the repository and base_tags from
# infra/active/root-context.yaml (the literals below), and derives every
# resource name in the platform from name_prefix and names; tags flow into the
# provider default_tags. The expected values were established by running this
# file against the v0.1.0 code, not by reading v1.
#
# If an assertion here fails, the change under test alters values that live
# resources are named and tagged with. It is a major-version decision that
# forces replacement of real resources, never a test to update.

variables {
  environment = "dev"
  repository  = "hatan4ik/devops-aws-infra"

  base_tags = {
    Application = "platform"
    CostCenter  = "platform-bootstrap"
    Owner       = "hatan4ik"
  }
}

run "sandbox_network" {
  command = plan

  variables {
    root            = "sandbox-network"
    name_components = ["sandbox", "network", "dev"]
  }

  assert {
    condition     = output.name_prefix == "sandbox-network-dev"
    error_message = "GOLDEN MASTER: name_prefix for sandbox-network changed. It names the live VPC; changing it breaks live resource names and forces replacement."
  }

  assert {
    condition = output.names == {
      default = "sandbox-network-dev"
    }
    error_message = "GOLDEN MASTER: names for sandbox-network changed. Its shape and values are consumed by name; changing them breaks live resource names."
  }

  assert {
    condition = output.tags == {
      Application = "platform"
      CostCenter  = "platform-bootstrap"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "hatan4ik"
      Repository  = "hatan4ik/devops-aws-infra"
      Root        = "sandbox-network"
    }
    error_message = "GOLDEN MASTER: tags for sandbox-network changed. They are the provider default_tags of a live root; changing them rewrites the tags of every live resource."
  }
}

run "sandbox_platform" {
  command = plan

  variables {
    root            = "sandbox-platform"
    name_components = ["sandbox", "platform", "dev"]
    additional_names = {
      network  = ["sandbox", "network", "dev"]
      workload = ["sandbox", "workload", "dev"]
    }
  }

  assert {
    condition     = output.name_prefix == "sandbox-platform-dev"
    error_message = "GOLDEN MASTER: name_prefix for sandbox-platform changed. It names the live ECS platform core; changing it breaks live resource names and forces replacement."
  }

  assert {
    condition = output.names == {
      default  = "sandbox-platform-dev"
      network  = "sandbox-network-dev"
      workload = "sandbox-workload-dev"
    }
    error_message = "GOLDEN MASTER: names for sandbox-platform changed. names.network selects the live VPC and names.workload builds the live log group ARN; changing them breaks live resource names."
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
    error_message = "GOLDEN MASTER: tags for sandbox-platform changed. They are the provider default_tags of a live root; changing them rewrites the tags of every live resource."
  }
}

run "sandbox_workload" {
  command = plan

  variables {
    root            = "sandbox-workload"
    name_components = ["sandbox", "workload", "dev"]
    additional_names = {
      network  = ["sandbox", "network", "dev"]
      platform = ["sandbox", "platform", "dev"]
    }
  }

  assert {
    condition     = output.name_prefix == "sandbox-workload-dev"
    error_message = "GOLDEN MASTER: name_prefix for sandbox-workload changed. It names the live ECS service; changing it breaks live resource names and forces replacement."
  }

  assert {
    condition = output.names == {
      default  = "sandbox-workload-dev"
      network  = "sandbox-network-dev"
      platform = "sandbox-platform-dev"
    }
    error_message = "GOLDEN MASTER: names for sandbox-workload changed. names.platform builds the live cluster name, KMS alias and DynamoDB table lookups; changing them breaks live resource names."
  }

  assert {
    condition = output.tags == {
      Application = "platform"
      CostCenter  = "platform-bootstrap"
      Environment = "dev"
      ManagedBy   = "terraform"
      Owner       = "hatan4ik"
      Repository  = "hatan4ik/devops-aws-infra"
      Root        = "sandbox-workload"
    }
    error_message = "GOLDEN MASTER: tags for sandbox-workload changed. They are the provider default_tags of a live root; changing them rewrites the tags of every live resource."
  }
}

# The derived names the roots actually build from names.*. If the join or the
# separator ever changes, these strings change with it.
run "derived_live_names" {
  command = plan

  variables {
    root            = "sandbox-workload"
    name_components = ["sandbox", "workload", "dev"]
    additional_names = {
      network  = ["sandbox", "network", "dev"]
      platform = ["sandbox", "platform", "dev"]
    }
  }

  assert {
    condition     = "${output.names.platform}-cluster" == "sandbox-platform-dev-cluster"
    error_message = "GOLDEN MASTER: the live ECS cluster name (names.platform + -cluster) changed; this breaks live resource names."
  }

  assert {
    condition     = "alias/${output.names.platform}-application-data" == "alias/sandbox-platform-dev-application-data"
    error_message = "GOLDEN MASTER: the live KMS alias name (alias/ + names.platform + -application-data) changed; this breaks live resource names."
  }

  assert {
    condition     = "${output.names.platform}-session" == "sandbox-platform-dev-session"
    error_message = "GOLDEN MASTER: the live DynamoDB table name (names.platform + -session) changed; this breaks live resource names."
  }
}
