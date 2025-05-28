# 1) CloudWatch Log Group 
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.service_name}-${var.environment}"
  retention_in_days = var.log_retention_in_days

  tags = {
    Environment = var.environment
    Service     = var.service_name
  }
}

# 2) Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.service_name}-${var.environment}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.execution_role_arn

  container_definitions = jsonencode([{
    name         = var.service_name
    image        = var.container_image
    essential    = true
    portMappings = [{ containerPort = var.container_port }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = var.service_name
      }
    }
  }])
}

# 3) Service
resource "aws_ecs_service" "this" {
  name            = "${var.service_name}-${var.environment}"
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  depends_on = [
    aws_cloudwatch_log_group.ecs,
    aws_ecs_task_definition.this,
  ]
}
