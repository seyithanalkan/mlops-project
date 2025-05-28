module "ecs_cluster" {
  source       = "../modules/ecs-cluster"
  environment  = var.environment
  cluster_name = var.cluster_name
}
