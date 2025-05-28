output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "The ECS task definition family (no revision) so EventBridge always uses the latest"
  value       = aws_ecs_task_definition.this.family
}
