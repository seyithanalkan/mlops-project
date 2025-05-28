# Log Group  
resource "aws_cloudwatch_log_group" "ecs_task" {
  name              = "/ecs/${var.task_name}-${var.environment}"
  retention_in_days = 14

  tags = {
    Environment = var.environment
    Name        = "/ecs/${var.task_name}-${var.environment}"
  }
}

#Task Definiton
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.task_name}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.execution_role_arn

  container_definitions = jsonencode([{
    name      = var.task_name
    image     = var.container_image
    essential = true
    command   = var.command

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ecs_task.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = var.task_name
      }
    }

    environment = [
      {
        name  = "ECS_CLUSTER"
        value = var.cluster_name        # pass this into the module
      },
      {
        name  = "ECS_SERVICE"
        value = var.serve_service_name  # pass this into the module
      }
    ]
  }])

  tags = {
    Environment = var.environment
    Name        = "${var.task_name}-task-${var.environment}"
  }
}
