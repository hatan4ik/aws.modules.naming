# One module call per environment. The module holds no state, so a for_each over
# the environments produces one independent set of names and tags for each.
module "naming" {
  source   = "../../"
  for_each = var.environments

  environment     = each.key
  root            = var.root
  repository      = var.repository
  name_components = [var.application, "api", each.key]

  additional_names = {
    database = [var.application, "db", each.key]
  }

  base_tags = {
    Application = var.application
    Owner       = var.owner
  }

  # Application and network load balancer names, and target group names, are
  # limited to 32 characters. Failing at 32 here turns an apply-time error from
  # AWS into a plan-time error naming the offending name.
  name_max_length = 32
}
