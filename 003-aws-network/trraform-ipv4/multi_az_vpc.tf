# ----------------------------
# Multi-AZ VPC
# ----------------------------
resource "aws_vpc" "multi_az_vpc" {
  cidr_block           = var.multi_az_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "multi-az-vpc"
  }
}

# ----------------------------
# Subnets
# ----------------------------
resource "aws_subnet" "multi_az_public_a" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  cidr_block        = var.multi_az_public_subnet_a_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "public-subnet-a-demo"
  }
}

resource "aws_subnet" "multi_az_public_c" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  cidr_block        = var.multi_az_public_subnet_c_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "public-subnet-c-demo"
  }
}

resource "aws_subnet" "multi_az_private_a" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  cidr_block        = var.multi_az_private_subnet_a_cidr
  availability_zone = var.availability_zone_1

  tags = {
    Name = "private-subnet-a-demo"
  }
}

resource "aws_subnet" "multi_az_private_c" {
  vpc_id            = aws_vpc.multi_az_vpc.id
  cidr_block        = var.multi_az_private_subnet_c_cidr
  availability_zone = var.availability_zone_2

  tags = {
    Name = "private-subnet-c-demo"
  }
}

# ----------------------------
# Internet Gateway
# ----------------------------
resource "aws_internet_gateway" "multi_az_igw" {
  vpc_id = aws_vpc.multi_az_vpc.id

  tags = {
    Name = "multi-az-igw"
  }
}

# ----------------------------
# NAT Gateway
# ----------------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-gateway-eip"
  }
}

resource "aws_nat_gateway" "multi_az_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.multi_az_public_a.id

  tags = {
    Name = "nat-gateway-demo"
  }

  depends_on = [aws_internet_gateway.multi_az_igw]
}

# ----------------------------
# Route Tables
# ----------------------------
resource "aws_route_table" "multi_az_public" {
  vpc_id = aws_vpc.multi_az_vpc.id

  tags = {
    Name = "public-root-tbl"
  }
}

resource "aws_route" "multi_az_public_internet" {
  route_table_id         = aws_route_table.multi_az_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.multi_az_igw.id
}

resource "aws_route_table_association" "multi_az_public_a" {
  subnet_id      = aws_subnet.multi_az_public_a.id
  route_table_id = aws_route_table.multi_az_public.id
}

resource "aws_route_table_association" "multi_az_public_c" {
  subnet_id      = aws_subnet.multi_az_public_c.id
  route_table_id = aws_route_table.multi_az_public.id
}

resource "aws_route_table" "multi_az_private" {
  vpc_id = aws_vpc.multi_az_vpc.id

  tags = {
    Name = "private-root-tbl"
  }
}

resource "aws_route" "multi_az_private_nat" {
  route_table_id         = aws_route_table.multi_az_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.multi_az_nat.id
}

resource "aws_route" "multi_az_to_single_az" {
  route_table_id         = aws_route_table.multi_az_private.id
  destination_cidr_block = var.single_az_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route_table_association" "multi_az_private_a" {
  subnet_id      = aws_subnet.multi_az_private_a.id
  route_table_id = aws_route_table.multi_az_private.id
}

resource "aws_route_table_association" "multi_az_private_c" {
  subnet_id      = aws_subnet.multi_az_private_c.id
  route_table_id = aws_route_table.multi_az_private.id
}

# ----------------------------
# Security Groups
# ----------------------------
resource "aws_security_group" "multi_az_public_sg" {
  name        = "public-sg"
  description = "Allow HTTP traffic"
  vpc_id      = aws_vpc.multi_az_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.sg_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

resource "aws_security_group" "multi_az_private_sg" {
  name        = "private-sg"
  description = "Allow HTTP traffic and SSM access"
  vpc_id      = aws_vpc.multi_az_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.multi_az_vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.multi_az_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}

# ----------------------------
# EC2 Instances
# ----------------------------
resource "aws_instance" "ec2_instance_a" {
  ami                    = data.aws_ssm_parameter.amazon_linux.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.multi_az_private_a.id
  vpc_security_group_ids = [aws_security_group.multi_az_private_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash -x
    dnf install -y httpd
    echo "<h1>Hello from Private Subnet A</h1>" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name = "ec2-private-a"
  }
}

resource "aws_instance" "ec2_instance_c" {
  ami                    = data.aws_ssm_parameter.amazon_linux.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.multi_az_private_c.id
  vpc_security_group_ids = [aws_security_group.multi_az_private_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash -xe
    dnf install -y httpd
    echo "<h1>Hello from Private Subnet C</h1>" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name = "ec2-private-c"
  }
}

# ----------------------------
# Application Load Balancer
# ----------------------------
resource "aws_lb" "multi_az_alb" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.multi_az_public_a.id, aws_subnet.multi_az_public_c.id]

  tags = {
    Name = "demo-alb"
  }
}

resource "aws_lb_target_group" "multi_az_tg" {
  name     = "demo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.multi_az_vpc.id

  health_check {
    path = "/"
    protocol = "HTTP"
  }

  tags = {
    Name = "demo-tg"
  }
}

resource "aws_lb_target_group_attachment" "tg_attachment_a" {
  target_group_arn = aws_lb_target_group.multi_az_tg.arn
  target_id        = aws_instance.ec2_instance_a.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_c" {
  target_group_arn = aws_lb_target_group.multi_az_tg.arn
  target_id        = aws_instance.ec2_instance_c.id
  port             = 80
}

resource "aws_lb_listener" "multi_az_listener" {
  load_balancer_arn = aws_lb.multi_az_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.multi_az_tg.arn
  }
}