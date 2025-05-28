data "aws_availability_zones" "available" {
  state = "available"
}

module "networking" {
  source             = "../modules/networking"
  vpc_name           = var.environment
  cidr_block         = var.vpc_cidr
  availability_zones = data.aws_availability_zones.available.names
  subnet_bits        = var.subnet_bits
}
