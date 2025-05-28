resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-${var.environment}-sg"
  description = "SG for ${var.name_prefix} in ${var.environment}"
  vpc_id      = var.vpc_id

  # CIDR-based ingress
  dynamic "ingress" {
    for_each = var.ingress
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # SG-based ingress
  dynamic "ingress" {
    for_each = var.ingress_security_groups
    content {
      from_port       = var.ingress[0].from_port    # aynı port aralığını kullanır
      to_port         = var.ingress[0].to_port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  # Egress rules
  dynamic "egress" {
    for_each = var.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-${var.environment}-sg"
  }
}

