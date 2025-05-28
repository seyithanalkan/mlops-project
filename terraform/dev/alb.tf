module "alb" {
  source             = "../modules/alb"
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  security_group_ids = [module.alb_sg.sg_id]
  certificate_arn    = var.alb_certificate_arn
  listener_port      = var.alb_listener_port
  target_port        = var.serve_container_port
}
