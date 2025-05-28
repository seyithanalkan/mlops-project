# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  tags = {
    Environment = var.environment
  }
}

# Target Group for ECS
resource "aws_lb_target_group" "this" {
  name     = "${var.environment}-tg"
  port     = var.target_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip" 
  deregistration_delay = 15  

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2

  }

  tags = {
    Environment = var.environment
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
