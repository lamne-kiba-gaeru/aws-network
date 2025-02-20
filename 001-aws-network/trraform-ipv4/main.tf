# ----------------------------
# Provider
# ----------------------------
# ここら辺はご自身の作業環境に合わせてください
provider "aws" {
  region = "ap-northeast-1"
}

# ----------------------------
# Variables
# ----------------------------
# ここら辺はご自身の作業環境に合わせてください
variable   "availability_zone"  {
  description = "Availability Zone"
  type        = string
  default     = "ap-northeast-1a"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_cidr_block"  {
  description = "Public Subnet CIDR Block"
  type        = string
  default     = "10.0.0.0/27"
}

variable "sg_cidr_block" {
  description = "Security Group CIDR Block"
  type        = string
  default     = "10.1.2.0/27"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "public-vpc-demo"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = var.availability_zone
  tags = {
    Name = "public-subnet-demo"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id            = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-root-tbl"
  }
}

resource "aws_route" "main" {
  route_table_id     = aws_route_table.main.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id        = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "main" {
  subnet_id     = aws_subnet.public.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "public" {
  name        = "public-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.sg_cidr_block]
  }
}
