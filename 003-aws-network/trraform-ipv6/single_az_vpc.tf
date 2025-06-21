# ----------------------------
# Single-AZ VPC
# ----------------------------
resource "aws_vpc" "single_az_vpc" {
  cidr_block           = var.single_az_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "single-az-vpc"
  }
}

# ----------------------------
# Subnets
# ----------------------------
resource "aws_subnet" "single_az_public" {
  vpc_id                  = aws_vpc.single_az_vpc.id
  cidr_block              = var.single_az_public_subnet_cidr
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true
  
  # IPv6設定
  ipv6_cidr_block = cidrsubnet(aws_vpc.single_az_vpc.ipv6_cidr_block, 8, 4)
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "single-az-public-subnet"
  }
}

resource "aws_subnet" "single_az_private" {
  vpc_id            = aws_vpc.single_az_vpc.id
  cidr_block        = var.single_az_private_subnet_cidr
  availability_zone = var.availability_zone_1
  
  # IPv6設定
  ipv6_cidr_block = cidrsubnet(aws_vpc.single_az_vpc.ipv6_cidr_block, 8, 5)
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "single-az-private-subnet"
  }
}

# ----------------------------
# Internet Gateway
# ----------------------------
resource "aws_internet_gateway" "single_az_igw" {
  vpc_id = aws_vpc.single_az_vpc.id

  tags = {
    Name = "single-az-igw"
  }
}

# ----------------------------
# Egress-Only Internet Gateway for IPv6
# ----------------------------
resource "aws_egress_only_internet_gateway" "single_az_eigw" {
  vpc_id = aws_vpc.single_az_vpc.id

  tags = {
    Name = "single-az-eigw"
  }
}

# ----------------------------
# NAT Gateway
# ----------------------------
resource "aws_eip" "single_az_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "single-az-nat-eip"
  }
}

resource "aws_nat_gateway" "single_az_nat" {
  allocation_id = aws_eip.single_az_nat_eip.id
  subnet_id     = aws_subnet.single_az_public.id

  tags = {
    Name = "single-az-nat-gateway"
  }

  depends_on = [aws_internet_gateway.single_az_igw]
}

# ----------------------------
# Route Tables
# ----------------------------
resource "aws_route_table" "single_az_public" {
  vpc_id = aws_vpc.single_az_vpc.id

  tags = {
    Name = "single-az-public-rtb"
  }
}

# IPv4 インターネットルート
resource "aws_route" "single_az_public_internet_ipv4" {
  route_table_id         = aws_route_table.single_az_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.single_az_igw.id
}

# IPv6 インターネットルート
resource "aws_route" "single_az_public_internet_ipv6" {
  route_table_id              = aws_route_table.single_az_public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.single_az_igw.id
}

resource "aws_route_table_association" "single_az_public" {
  subnet_id      = aws_subnet.single_az_public.id
  route_table_id = aws_route_table.single_az_public.id
}

resource "aws_route_table" "single_az_private" {
  vpc_id = aws_vpc.single_az_vpc.id

  tags = {
    Name = "single-az-private-rtb"
  }
}

# IPv4 NATゲートウェイルート
resource "aws_route" "single_az_private_nat_ipv4" {
  route_table_id         = aws_route_table.single_az_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.single_az_nat.id
}

# IPv6 Egress-Only IGWルート
resource "aws_route" "single_az_private_eigw_ipv6" {
  route_table_id              = aws_route_table.single_az_private.id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.single_az_eigw.id
}

# IPv4 VPCピアリングルート
resource "aws_route" "single_az_to_multi_az_ipv4" {
  route_table_id         = aws_route_table.single_az_private.id
  destination_cidr_block = var.multi_az_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
}

# IPv6 VPCピアリングルート
resource "aws_route" "single_az_to_multi_az_ipv6" {
  route_table_id              = aws_route_table.single_az_private.id
  destination_ipv6_cidr_block = aws_vpc.multi_az_vpc.ipv6_cidr_block
  vpc_peering_connection_id   = aws_vpc_peering_connection.vpc_peering.id
}

resource "aws_route_table_association" "single_az_private" {
  subnet_id      = aws_subnet.single_az_private.id
  route_table_id = aws_route_table.single_az_private.id
}

# ----------------------------
# Security Group
# ----------------------------
resource "aws_security_group" "single_az_ec2_sg" {
  name        = "single-az-ec2-sg"
  description = "Allow HTTP traffic and SSM access"
  vpc_id      = aws_vpc.single_az_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.multi_az_vpc_cidr]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = [aws_vpc.multi_az_vpc.ipv6_cidr_block]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.single_az_vpc_cidr]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = [aws_vpc.single_az_vpc.ipv6_cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "single-az-ec2-sg"
  }
}

# ----------------------------
# EC2 Instance
# ----------------------------
resource "aws_instance" "single_az_ec2" {
  ami                    = data.aws_ssm_parameter.amazon_linux.value
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.single_az_private.id
  vpc_security_group_ids = [aws_security_group.single_az_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  
  # IPv6アドレスを割り当て
  ipv6_address_count     = 1

  user_data = <<-EOF
    #!/bin/bash -x
    dnf install -y httpd
    echo "<h1>Hello from Single AZ VPC (IPv6 enabled)</h1>" > /var/www/html/index.html
    systemctl start httpd
    systemctl enable httpd
  EOF

  tags = {
    Name = "ec2-single-az"
  }
}