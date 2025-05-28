output "ecs_task_exec_role_arn" {
  description = "ARN of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_exec.arn
}

output "ecs_task_exec_role_name" {
  description = "Name of the ECS Task Execution Role"
  value       = aws_iam_role.ecs_task_exec.name
}

output "eb_run_task_role_arn" {
  description = "ARN of the IAM Role that EventBridge assumes to RunTask"
  value       = aws_iam_role.eb_run_task.arn
}