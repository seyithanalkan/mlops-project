module "alb_sg" {
  source      = "../modules/security-group"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  name_prefix = "alb"

  ingress = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "serve_sg" {
  source      = "../modules/security-group"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  name_prefix = var.serve_service_name

  ingress = [
    {
      from_port   = var.serve_container_port
      to_port     = var.serve_container_port
      protocol    = "tcp"
      cidr_blocks = []
    }
  ]

  ingress_security_groups = [
    module.alb_sg.sg_id
  ]
}




module "train_sg" {
  source      = "../modules/security-group"
  environment = var.environment
  vpc_id      = module.networking.vpc_id
  name_prefix = var.train_task_name


  ingress = []


}