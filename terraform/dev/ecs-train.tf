module "train_task" {
  source             = "../modules/ecs-task-fargate"
  environment        = var.environment
  task_name          = var.train_task_name
  container_image    = "${module.ecr_train.repository_url}:${var.environment}"
  execution_role_arn = module.iam.ecs_task_exec_role_arn
  subnet_ids         = module.networking.private_subnet_ids
  security_group_ids = [module.train_sg.sg_id]
  aws_region         = var.aws_region
  cpu                = var.train_cpu
  memory             = var.train_memory
  cluster_name       = module.ecs_cluster.cluster_name
  serve_service_name = module.serve.service_name
}
data "aws_caller_identity" "current" {}

locals {

  train_family = "${var.train_task_name}-${var.environment}"

  train_task_definition_arn_only = "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${local.train_family}"
}

module "on_raw_event" {
  source = "../modules/events"

  environment          = var.environment
  raw_bucket_name      = module.s3.bucket_name

  cluster_arn          = module.ecs_cluster.cluster_arn
  task_definition_arn  = "${local.train_task_definition_arn_only}"

  eventbridge_role_arn = module.iam.eb_run_task_role_arn

  subnet_ids           = module.networking.private_subnet_ids
  security_group_ids   = [module.train_sg.sg_id]
}
