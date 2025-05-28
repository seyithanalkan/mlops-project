module "iam" {
  source               = "../modules/iam"
  environment          = var.environment
  raw_bucket_arn       = module.s3.bucket_arn
  processed_bucket_arn = module.processed_s3.bucket_arn
  model_bucket_arn     = module.model_s3.bucket_arn
  cluster_arn          = module.ecs_cluster.cluster_arn
  task_definition_arn  = module.train_task.task_definition_arn
  aws_region           = var.aws_region
  train_task_name      = var.train_task_name
  train_task_family    = "${var.train_task_name}-${var.environment}"
  serve_service_arn    = data.aws_ecs_service.serve.arn
}

data "aws_ecs_service" "serve" {
  cluster_arn = module.ecs_cluster.cluster_arn
  service_name = module.serve.service_name
}