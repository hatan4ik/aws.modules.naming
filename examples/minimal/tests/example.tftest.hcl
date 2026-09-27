variables {
  environment = "prod"
  root        = "payments-api"
  repository  = "acme/infrastructure"
  application = "payments"
}

run "emits_one_name_and_the_canonical_tags" {
  command = plan

  assert {
    condition     = output.name == "payments-prod"
    error_message = "The name must be the application and environment joined with a hyphen."
  }

  assert {
    condition = output.tags == {
      Environment = "prod"
      ManagedBy   = "terraform"
      Repository  = "acme/infrastructure"
      Root        = "payments-api"
    }
    error_message = "Without base_tags the tags are exactly the four canonical tags."
  }
}
