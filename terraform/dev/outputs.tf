output "ecs_task_execution_role_arn" {
  value = module.iam.ecs_task_exec_role_arn
}

output "ecr_train_url" {
  description = "URI for train ECR repo"
  value       = module.ecr_train.repository_url
}

output "ecr_serve_url" {
  description = "URI for serve ECR repo"
  value       = module.ecr_serve.repository_url
}

output "ecs_cluster_arn" {
  value = module.ecs_cluster.cluster_arn
}
output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "serve_service_name" {
  value = module.serve.service_name
}


output "serve_task_definition_arn" {
  value = module.serve.task_definition_arn
}

output "serve_sg_id" {
  value = module.serve_sg.sg_id
}

output "train_task_definition_arn" {
  value = module.train_task.task_definition_arn
}

output "alb_arn" {
  value = module.alb.alb_arn
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "alb_tg_arn" {
  value = module.alb.target_group_arn
}

# Raw-data bucket outputs
output "raw_bucket_name" {
  description = "Name of the raw-data S3 bucket"
  value       = module.s3.bucket_name
}

output "raw_bucket_arn" {
  description = "ARN of the raw-data S3 bucket"
  value       = module.s3.bucket_arn
}

# Processed-data bucket outputs
output "processed_bucket_name" {
  description = "Name of the processed-data S3 bucket"
  value       = module.processed_s3.bucket_name
}

output "processed_bucket_arn" {
  description = "ARN of the processed-data S3 bucket"
  value       = module.processed_s3.bucket_arn
}

output "model_bucket_name" {
  description = "Name of the model artifact S3 bucket"
  value       = module.model_s3.bucket_name
}

output "model_bucket_arn" {
  description = "ARN of the model artifact S3 bucket"
  value       = module.model_s3.bucket_arn
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (for Fargate tasks)"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnet_ids
}
#