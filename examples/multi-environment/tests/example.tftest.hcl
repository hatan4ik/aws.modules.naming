variables {
  environments = ["dev", "prod"]
  root         = "payments-api"
  repository   = "acme/infrastructure"
  application  = "payments"
  owner        = "payments-team"
}

run "names_every_environment_independently" {
  command = plan

  assert {
    condition = output.name_prefixes == {
      dev  = "payments-api-dev"
      prod = "payments-api-prod"
    }
    error_message = "Each environment must get its own default name."
  }

  assert {
    condition = output.names == {
      dev = {
        default  = "payments-api-dev"
        database = "payments-db-dev"
      }
      prod = {
        default  = "payments-api-prod"
        database = "payments-db-prod"
      }
    }
    error_message = "Each environment must get its default and additional names."
  }

  assert {
    condition     = output.tags.dev.Environment == "dev" && output.tags.prod.Environment == "prod" && output.tags.prod.Owner == "payments-team"
    error_message = "Tags carry each call's own environment and the shared allocation tags."
  }
}
