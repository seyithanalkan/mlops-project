module "ecr_train" {
  source      = "../modules/ecr"
  environment = var.environment
  repo_name   = var.train_repo_name
}

module "ecr_serve" {
  source      = "../modules/ecr"
  environment = var.environment
  repo_name   = var.serve_repo_name
}
