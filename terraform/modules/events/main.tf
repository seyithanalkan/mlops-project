# 1) S3 -> EventBridge Rule
resource "aws_cloudwatch_event_rule" "on_new_raw" {
  name = "on-new-raw-${var.environment}"
  event_pattern = jsonencode({
    source       = ["aws.s3"],
    "detail-type"= ["Object Created"],
    detail = {
      bucket = { name = [var.raw_bucket_name] },
      object = { key = [{ prefix = "data/raw/" }] }
    }
  })
}

# 2) EventBridge Target: Run ECS Fargate task
resource "aws_cloudwatch_event_target" "run_task" {
  rule     = aws_cloudwatch_event_rule.on_new_raw.name
  arn      = var.cluster_arn
  role_arn = var.eventbridge_role_arn

  ecs_target {
    task_definition_arn = var.task_definition_arn
    task_count          = 1
    launch_type         = "FARGATE"
    network_configuration {
      subnets          = var.subnet_ids
      security_groups  = var.security_group_ids
      assign_public_ip = false
    }
  }
}
