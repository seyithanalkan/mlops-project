module "serve" {
  source               = "../modules/ecs-service-fargate"
  environment          = var.environment
  cluster_arn          = module.ecs_cluster.cluster_arn
  service_name         = var.serve_service_name
  container_image      = "${module.ecr_serve.repository_url}:${var.environment}"
  container_port       = var.serve_container_port
  cpu                  = var.serve_cpu
  memory               = var.serve_memory
  subnet_ids           = module.networking.private_subnet_ids
  security_group_ids   = [module.serve_sg.sg_id]
  execution_role_arn   = module.iam.ecs_task_exec_role_arn
  aws_region           = var.aws_region
  alb_target_group_arn = module.alb.target_group_arn

}

