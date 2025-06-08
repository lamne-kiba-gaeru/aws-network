# ----------------------------
# Provider
# ----------------------------
# ここら辺はご自身の作業環境に合わせてください
# プロバイダの指定
provider "aws" {
  region = "ap-northeast-1"
}

# ----------------------------
# Variables
# ----------------------------
variable "availability_zone_1" {
  description = "The first availability zone."
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "The second availability zone."
  type        = string
  default     = "us-east-1c"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "latest_ami_id" {
  description = "The latest Amazon Linux 2023 AMI ID."
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_a_cidr_block" {
  description = "The CIDR block for the public subnet A."
  type        = string
  default     = "10.0.0.0/27"
}

variable "public_subnet_c_cidr_block" {
  description = "The CIDR block for the public subnet C."
  type        = string
  default     = "10.0.0.32/27"
}

variable "private_subnet_a_cidr_block" {
  description = "The CIDR block for the private subnet A."
  type        = string
  default     = "10.0.0.64/27"
}

variable "private_subnet_c_cidr_block" {
  description = "The CIDR block for the private subnet C."
  type        = string
  default     = "10.0.0.96/27"
}

variable "sg_cidr_block" {
  description = "The CIDR block for the security group ingress rule."
  type        = string
  default     = "10.1.2.0/27"
}

# AWSリソース
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-demo"
  }
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = var.availability_zone_1

  tags = {
    Name = "public-subnet-a-demo"
  }
}

resource "aws_subnet" "public_subnet_c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public_subnet_c_cidr_block
  availability_zone = var.availability_zone_2

  tags = {
    Name = "public-subnet-c-demo"
  }
}

resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_a_cidr_block
  availability_zone = var.availability_zone_1

  tags = {
    Name = "private-subnet-a-demo"
  }
}

resource "aws_subnet" "private_subnet_c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_c_cidr_block
  availability_zone = var.availability_zone_2

  tags = {
    Name = "private-subnet-c-demo"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "public-root-tbl"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "public_subnet_a_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_c_route_table_association" {
  subnet_id      = aws_subnet.public_subnet_c.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_eip" "nat_gateway_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "nat-gateway-demo"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private-root-tbl"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "private_subnet_a_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_c_route_table_association" {
  subnet_id      = aws_subnet.private_subnet_c.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_security_group" "public_security_group" {
  name        = "public-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.sg_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group" "alb_security_group" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

resource "aws_security_group" "private_security_group" {
  name        = "private-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

data "aws_ssm_parameter" "ami_id" {
  name = var.latest_ami_id
}

resource "aws_instance" "ec2_instance_a" {
  instance_type          = var.instance_type
  ami                    = data.aws_ssm_parameter.ami_id.value
  subnet_id              = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  user_data = base64encode(<<EOF
#!/bin/bash -xe
dnf install -y httpd
echo "<h1>Hello from Private Subnet A</h1>" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF
  )

  tags = {
    Name = "ec2-private-a"
  }
}

resource "aws_instance" "ec2_instance_c" {
  instance_type          = var.instance_type
  ami                    = data.aws_ssm_parameter.ami_id.value
  subnet_id              = aws_subnet.private_subnet_c.id
  vpc_security_group_ids = [aws_security_group.private_security_group.id]
  user_data = base64encode(<<EOF
#!/bin/bash -xe
dnf update -y
dnf install -y httpd
echo "<h1>Hello from Private Subnet C</h1>" > /var/www/html/index.html
systemctl start httpd
systemctl enable httpd
EOF
  )

  tags = {
    Name = "ec2-private-c"
  }
}

resource "aws_lb" "application_load_balancer" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets = [
    aws_subnet.public_subnet_a.id,
    aws_subnet.public_subnet_c.id
  ]

  tags = {
    Name = "demo-alb"
  }
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  health_check {
    path     = "/"
    protocol = "HTTP"
  }

  target_type = "instance"

  tags = {
    Name = "demo-tg"
  }
}

resource "aws_lb_target_group_attachment" "ec2_instance_a_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_instance_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "ec2_instance_c_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_instance.ec2_instance_c.id
  port             = 80
}


resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

output "load_balancer_dns" {
  description = "DNS Name of the Application Load Balancer"
  value       = aws_lb.application_load_balancer.dns_name
}

