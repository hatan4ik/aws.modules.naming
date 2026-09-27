variables {
  environment = "dev"
}

run "reproduces_the_sandbox_platform_call" {
  command = plan

  assert {
    condition     = output.name_prefix == "sandbox-platform-dev"
    error_message = "The default name must be sandbox-platform-dev."
  }

  assert {
    condition = output.names == {
      default  = "sandbox-platform-dev"
      network  = "sandbox-network-dev"
      workload = "sandbox-workload-dev"
    }
    error_message = "names must hold the default and the two neighbouring roots."
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
    error_message = "tags must combine the root-context.yaml base tags with the four canonical tags."
  }
}

run "derives_resource_names_from_the_outputs" {
  command = plan

  assert {
    condition     = terraform_data.platform_contract.input.cluster_name == "sandbox-platform-dev-cluster"
    error_message = "The cluster name is the name prefix plus -cluster."
  }

  assert {
    condition     = terraform_data.platform_contract.input.workload_log_group == "/aws/ecs/sandbox-workload-dev"
    error_message = "The workload log group path is built from names.workload."
  }
}
