resource "aws_ecs_cluster" "this" {
  name = "${var.cluster_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = var.environment
    Name        = "${var.cluster_name}-${var.environment}"
  }
}