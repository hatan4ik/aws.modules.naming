module "naming" {
  source = "../../"

  environment     = var.environment
  root            = var.root
  repository      = var.repository
  name_components = [var.application, var.environment]
}
