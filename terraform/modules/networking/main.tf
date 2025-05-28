locals {
  azs = var.availability_zones
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.vpc_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = toset(local.azs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, var.subnet_bits, index(local.azs, each.key))
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-${each.key}"
  }
}

# Elastic IP for NAT
resource "aws_eip" "nat" {

  tags = {
    Name = "${var.vpc_name}-nat-eip"
  }
}

# NAT Gateway in the first public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id

  subnet_id = aws_subnet.public[local.azs[0]].id

  tags = {
    Name = "${var.vpc_name}-nat-gw"
  }
}

# Private subnets
resource "aws_subnet" "private" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, var.subnet_bits, index(local.azs, each.key) + length(local.azs))
  availability_zone = each.key

  tags = {
    Name = "${var.vpc_name}-private-${each.key}"
  }
}

# Data (internal) subnets
resource "aws_subnet" "data" {
  for_each = toset(local.azs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.cidr_block, var.subnet_bits, index(local.azs, each.key) + length(local.azs) * 2)
  availability_zone = each.key

  tags = {
    Name = "${var.vpc_name}-data-${each.key}"
  }
}

# Public route table and associations
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.vpc_name}-public-rt" }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Private route table and NAT route
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.vpc_name}-private-rt" }
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Data route table (internal-only)
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "${var.vpc_name}-data-rt" }
}

resource "aws_route_table_association" "data_assoc" {
  for_each       = aws_subnet.data
  subnet_id      = each.value.id
  route_table_id = aws_route_table.data.id
}
